//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_file_manager.h>
#include <atomic>
#include <fstream>
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_audio_utils.h"
#include "yas_playing_math.h"
#include "yas_playing_path_utils.h"
#include "yas_playing_signal_file_info.h"
#include "yas_playing_timeline_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    std::string const _root_path;
    chaining::value::holder<std::vector<int64_t>> _ch_mapping{std::vector<int64_t>{}};

    // ロックここから
    std::atomic<int64_t> _play_frame = 0;
    std::atomic<bool> _is_playing = false;
    // ロックここまで

    impl(audio_renderable &&renderable, std::string const &root_path, task_queue &&queue)
        : _root_path(root_path), _renderable(std::move(renderable)), _queue(std::move(queue)) {
    }

    void prepare(audio_player &player) {
        this->_setup_chaining(player);
        this->_setup_rendering_handler(player);
    }

    void set_playing(bool is_playing) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_is_playing = is_playing;
        this->_renderable.set_is_rendering(is_playing);
    }

    void seek(int64_t const play_frame) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        uint32_t const file_length = this->_file_length();

        this->_play_frame = play_frame;

        if (file_length == 0) {
            return;
        }

        if (auto const top_file_idx = this->_top_file_idx()) {
            for (auto &buffer : this->_circular_buffers) {
                buffer->reload_all(*top_file_idx);
            }
        }
    }

    void reload(int64_t const ch_idx, int64_t const frag_idx) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        if (this->_circular_buffers.size() <= ch_idx) {
            return;
        }

        auto &buffer = this->_circular_buffers.at(ch_idx);
        buffer->reload(frag_idx);
    }

   private:
    chaining::observer_pool _pool;

    task_queue _queue;
    audio_renderable _renderable;
    chaining::value::holder<uint32_t> _ch_count{uint32_t(0)};
    chaining::value::holder<std::optional<audio::format>> _format{std::nullopt};
    chaining::receiver<> _update_circular_buffers_receiver = nullptr;

    // ロックここから
    std::vector<audio_circular_buffer::ptr> _circular_buffers;
    std::optional<audio::format> _locked_format{std::nullopt};
    // ロックここまで
    std::recursive_mutex _mutex;

    // render only
    audio::pcm_buffer _read_buffer{nullptr};

    void _setup_chaining(audio_player &player) {
        auto weak_player = to_weak(player);

        this->_update_circular_buffers_receiver = chaining::receiver<>{[weak_player](auto const &) {
            if (auto player = weak_player.lock()) {
                player.impl_ptr<impl>()->_update_circular_buffers();
            }
        }};

        this->_pool += this->_ch_mapping.chain().to_null().send_to(this->_update_circular_buffers_receiver).sync();

        this->_pool +=
            this->_renderable.chain_sample_rate()
                .combine(this->_renderable.chain_pcm_format())
                .to([](std::pair<double, audio::pcm_format> const &pair) {
                    if (pair.first > 0.0) {
                        return std::make_optional(audio::format{audio::format::args{.sample_rate = pair.first,
                                                                                    .channel_count = 1,
                                                                                    .pcm_format = pair.second,
                                                                                    .interleaved = false}});
                    } else {
                        return std::optional<audio::format>{std::nullopt};
                    }
                })
                .send_to(this->_format.receiver())
                .sync();

        this->_pool += this->_renderable.chain_channel_count().send_to(this->_ch_count.receiver()).sync();

        this->_pool += this->_format.chain()
                           .combine(this->_ch_count.chain())
                           .to_null()
                           .send_to(this->_update_circular_buffers_receiver)
                           .sync();
    }

    void _setup_rendering_handler(audio_player &player) {
        auto weak_player = to_weak(player);

        this->_renderable.set_rendering_handler([weak_player](audio::pcm_buffer &out_buffer) {
            if (out_buffer.format().is_interleaved()) {
                throw std::invalid_argument("out_buffer is not non-interleaved.");
            }

            auto player = weak_player.lock();
            if (!player) {
                return;
            }

            auto player_impl = player.impl_ptr<impl>();

            auto lock = std::unique_lock<std::recursive_mutex>(player_impl->_mutex, std::try_to_lock);

            if (!player_impl->_is_playing) {
                return;
            }

            int64_t const begin_play_frame = player_impl->_play_frame;
            int64_t play_frame = begin_play_frame;
            uint32_t const out_length = out_buffer.frame_length();
            int64_t const next_frame = play_frame + out_length;
            player_impl->_play_frame = next_frame;
            uint32_t const file_length = player_impl->_file_length();
            audio::format const &out_format = out_buffer.format();
            audio::format const read_format = audio::format{{.sample_rate = out_format.sample_rate(),
                                                             .pcm_format = out_format.pcm_format(),
                                                             .interleaved = false,
                                                             .channel_count = 1}};
            auto read_buffer = player_impl->_get_or_create_read_buffer(read_format, out_length);

            while (play_frame < next_frame) {
                auto const info = audio_utils::processing_info{play_frame, next_frame, file_length};
                uint32_t const to_frame = uint32_t(play_frame - begin_play_frame);

                auto each = make_fast_each(out_format.channel_count());
                while (yas_each_next(each)) {
                    auto const &idx = yas_each_index(each);

                    if (player_impl->_circular_buffers.size() <= idx) {
                        break;
                    }

                    read_buffer.clear();
                    read_buffer.set_frame_length(info.length);

                    auto &circular_buffer = player_impl->_circular_buffers.at(idx);
                    circular_buffer->read_into_buffer(read_buffer, play_frame);

                    out_buffer.copy_channel_from(
                        read_buffer, {.to_channel = idx, .to_begin_frame = to_frame, .length = info.length});

                    if (info.next_file_idx.has_value()) {
                        circular_buffer->rotate_buffer(*info.next_file_idx);
                    }
                }

                play_frame += info.length;
            }
        });
    }

    uint32_t _file_length() {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        if (auto const &format = this->_locked_format) {
            return static_cast<uint32_t>(format->sample_rate());
        } else {
            return 0;
        }
    }

    void _update_circular_buffers() {
        auto const &format_opt = this->_format.raw();
        if (!format_opt) {
            return;
        }
        auto const &format = *format_opt;

        uint32_t const ch_count = this->_ch_count.raw();
        std::vector<int64_t> const ch_mapping = this->_actually_ch_mapping();

        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_locked_format = format;
        this->_circular_buffers.clear();

        if (auto top_file_idx = this->_top_file_idx(); top_file_idx && ch_count > 0) {
            auto each = make_fast_each(int64_t(ch_count));
            while (yas_each_next(each)) {
                auto const ch_idx = ch_mapping.at(yas_each_index(each));
                auto const channel_path = path_utils::channel_path(this->_root_path, ch_idx);
                auto buffer = make_audio_circular_buffer(
                    format, 3, this->_queue, [channel_path](audio::pcm_buffer &buffer, int64_t const frag_idx) {
                        auto const frag_path = path_utils::fragment_path(channel_path, frag_idx);
                        auto const paths_result = file_manager::content_paths_in_directory(frag_path);
                        if (!paths_result) {
                            if (paths_result.error() == file_manager::content_paths_error::directory_not_found) {
                                return true;
                            } else {
                                return false;
                            }
                        }

                        auto const &paths = paths_result.value();

                        if (paths.size() == 0) {
                            return true;
                        }

                        auto const &format = buffer.format();
                        std::type_info const &sample_type = yas::to_sample_type(format.pcm_format());
                        if (sample_type == typeid(std::nullptr_t)) {
                            return false;
                        }

                        std::vector<signal_file_info> infos;
                        for (std::string const &path : paths) {
                            if (auto info = to_signal_file_info(path); info->sample_type == sample_type) {
                                infos.emplace_back(std::move(*info));
                            }
                        }

                        if (infos.size() == 0) {
                            return true;
                        }

                        int64_t const sample_rate = std::round(format.sample_rate());
                        int64_t const buf_top_frame = frag_idx * sample_rate;
                        int64_t const buf_next_frame = buf_top_frame + buffer.frame_length();
                        int64_t const sample_byte_count = format.sample_byte_count();

                        for (signal_file_info const &info : infos) {
                            if (info.range.frame < buf_top_frame || buf_next_frame < info.range.next_frame()) {
                                return false;
                            }

                            auto stream = std::fstream{info.path, std::ios_base::in | std::ios_base::binary};
                            if (!stream) {
                                return false;
                            }

                            int64_t const frame = (info.range.frame - buf_top_frame) * sample_byte_count;
                            int64_t const length = info.range.length * sample_byte_count;
                            char *data_ptr = timeline_utils::char_data(buffer);

                            stream.read(&data_ptr[frame], length);

                            if (stream.gcount() != length) {
                                return false;
                            }
                        }

                        return true;
                    });
                buffer->reload_all(*top_file_idx);
                this->_circular_buffers.push_back(std::move(buffer));
            }
        }
    }

    audio::pcm_buffer _get_or_create_read_buffer(audio::format const &format, uint32_t const length) {
        if (this->_read_buffer) {
            if (this->_read_buffer.format() != format) {
                this->_read_buffer = nullptr;
            } else if (this->_read_buffer.frame_capacity() < length) {
                this->_read_buffer = nullptr;
            }
        }

        if (!this->_read_buffer) {
            this->_read_buffer = audio::pcm_buffer{format, length};
        }

        return this->_read_buffer;
    }

    std::optional<int64_t> _top_file_idx() {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        uint32_t const file_length = this->_file_length();
        if (file_length > 0) {
            return math::floor_int(this->_play_frame, file_length) / file_length;
        } else {
            return std::nullopt;
        }
    }

    std::vector<int64_t> _actually_ch_mapping() {
        std::vector<int64_t> mapped;

        auto each = make_fast_each(this->_ch_count.raw());
        while (yas_each_next(each)) {
            mapped.push_back(this->_map_ch_idx(yas_each_index(each)));
        }

        return mapped;
    }

    int64_t _map_ch_idx(int64_t ch_idx) {
        auto const &mapping = this->_ch_mapping.raw();

        if (ch_idx < mapping.size()) {
            return mapping.at(ch_idx);
        } else {
            return ch_idx;
        }
    }
};

audio_player::audio_player(audio_renderable renderable, std::string const &root_path, task_queue queue)
    : base(std::make_shared<impl>(std::move(renderable), root_path, std::move(queue))) {
    impl_ptr<impl>()->prepare(*this);
}

audio_player::audio_player(std::nullptr_t) : base(nullptr) {
}

void audio_player::set_ch_mapping(std::vector<int64_t> ch_mapping) {
    impl_ptr<impl>()->_ch_mapping.set_value(std::move(ch_mapping));
}

void audio_player::set_playing(bool const is_playing) {
    impl_ptr<impl>()->set_playing(is_playing);
}

void audio_player::seek(int64_t const play_frame) {
    impl_ptr<impl>()->seek(play_frame);
}

void audio_player::reload(int64_t const ch_idx, int64_t const frag_idx) {
    impl_ptr<impl>()->reload(ch_idx, frag_idx);
}

std::string const &audio_player::root_path() const {
    return impl_ptr<impl>()->_root_path;
}

std::vector<int64_t> const &audio_player::ch_mapping() const {
    return impl_ptr<impl>()->_ch_mapping.raw();
}

bool audio_player::is_playing() const {
    return impl_ptr<impl>()->_is_playing;
}

int64_t audio_player::play_frame() const {
    return impl_ptr<impl>()->_play_frame;
}
