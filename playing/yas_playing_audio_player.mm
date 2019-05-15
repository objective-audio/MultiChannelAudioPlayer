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
#include "yas_playing_path.h"
#include "yas_playing_signal_file.h"
#include "yas_playing_signal_file_info.h"
#include "yas_playing_timeline_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    std::string const _root_path;
    chaining::value::holder<std::vector<channel_index_t>> _ch_mapping{std::vector<channel_index_t>{}};

    // ロックここから
    std::atomic<frame_index_t> _play_frame = 0;
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

    void seek(frame_index_t const play_frame) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        auto const frag_length = this->_frag_length();

        this->_play_frame = play_frame;

        if (frag_length == 0) {
            return;
        }

        if (auto const top_file_idx = this->_top_frag_idx()) {
            for (auto &buffer : this->_circular_buffers) {
                buffer->reload_all(*top_file_idx);
            }
        }
    }

    void reload(channel_index_t const ch_idx, fragment_index_t const frag_idx) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        if (this->_circular_buffers.size() <= ch_idx) {
            return;
        }

        auto &buffer = this->_circular_buffers.at(ch_idx);
        buffer->reload(frag_idx);
    }

    void reload_all() {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        auto const top_frag_idx = this->_top_frag_idx();
        if (!top_frag_idx) {
            return;
        }

        auto const ch_count = this->_ch_count.raw();

        auto ch_each = make_fast_each(ch_count);
        while (yas_each_next(ch_each)) {
            auto &circular_buffer = this->_circular_buffers.at(yas_each_index(ch_each));
            circular_buffer->reload_all(*top_frag_idx);
        }
    }

   private:
    chaining::observer_pool _pool;

    task_queue _queue;
    audio_renderable _renderable;
    chaining::value::holder<std::size_t> _ch_count{std::size_t(0)};
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

            frame_index_t const begin_play_frame = player_impl->_play_frame;
            frame_index_t play_frame = begin_play_frame;
            uint32_t const out_length = out_buffer.frame_length();
            frame_index_t const next_frame = play_frame + out_length;
            player_impl->_play_frame = next_frame;
            uint32_t const frag_length = player_impl->_frag_length();
            audio::format const &out_format = out_buffer.format();
            audio::format const read_format = audio::format{{.sample_rate = out_format.sample_rate(),
                                                             .pcm_format = out_format.pcm_format(),
                                                             .interleaved = false,
                                                             .channel_count = 1}};
            auto read_buffer = player_impl->_get_or_create_read_buffer(read_format, out_length);

            while (play_frame < next_frame) {
                auto const info = audio_utils::processing_info{play_frame, next_frame, frag_length};
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

                    if (info.next_frag_idx.has_value()) {
                        circular_buffer->rotate_buffer(*info.next_frag_idx);
                    }
                }

                play_frame += info.length;
            }
        });
    }

    proc::sample_rate_t _frag_length() {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        if (auto const &format = this->_locked_format) {
            return static_cast<proc::sample_rate_t>(format->sample_rate());
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

        std::size_t const ch_count = this->_ch_count.raw();
        std::vector<channel_index_t> const ch_mapping = this->_actually_ch_mapping();

        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_locked_format = format;
        this->_circular_buffers.clear();

        sample_rate_t const sample_rate = std::round(format.sample_rate());
        path::timeline const tl_path{this->_root_path, "0", sample_rate};

        if (auto top_file_idx = this->_top_frag_idx(); top_file_idx && ch_count > 0) {
            auto each = make_fast_each(channel_index_t(ch_count));
            while (yas_each_next(each)) {
                auto const ch_idx = ch_mapping.at(yas_each_index(each));
                auto buffer = make_audio_circular_buffer(
                    format, 3, this->_queue,
                    [ch_path = path::channel{tl_path, ch_idx}](audio::pcm_buffer &buffer,
                                                               fragment_index_t const frag_idx) {
                        buffer.clear();

                        auto const frag_path = path::fragment{ch_path, frag_idx};
                        auto const paths_result = file_manager::content_paths_in_directory(frag_path.string());
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

                        sample_rate_t const sample_rate = std::round(format.sample_rate());
                        frame_index_t const buf_top_frame = frag_idx * sample_rate;

                        for (signal_file_info const &info : infos) {
                            if (auto result = signal_file::read(info, buffer, buf_top_frame); !result) {
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

    std::optional<fragment_index_t> _top_frag_idx() {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        uint32_t const file_length = this->_frag_length();
        if (file_length > 0) {
            return math::floor_int(this->_play_frame, file_length) / file_length;
        } else {
            return std::nullopt;
        }
    }

    std::vector<channel_index_t> _actually_ch_mapping() {
        std::vector<channel_index_t> mapped;

        auto each = make_fast_each(this->_ch_count.raw());
        while (yas_each_next(each)) {
            mapped.push_back(this->_map_ch_idx(yas_each_index(each)));
        }

        return mapped;
    }

    channel_index_t _map_ch_idx(channel_index_t ch_idx) {
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

void audio_player::set_ch_mapping(std::vector<channel_index_t> ch_mapping) {
    impl_ptr<impl>()->_ch_mapping.set_value(std::move(ch_mapping));
}

void audio_player::set_playing(bool const is_playing) {
    impl_ptr<impl>()->set_playing(is_playing);
}

void audio_player::seek(frame_index_t const play_frame) {
    impl_ptr<impl>()->seek(play_frame);
}

void audio_player::reload(channel_index_t const ch_idx, fragment_index_t const frag_idx) {
    impl_ptr<impl>()->reload(ch_idx, frag_idx);
}

void audio_player::reload_all() {
    impl_ptr<impl>()->reload_all();
}

std::string const &audio_player::root_path() const {
    return impl_ptr<impl>()->_root_path;
}

std::vector<channel_index_t> const &audio_player::ch_mapping() const {
    return impl_ptr<impl>()->_ch_mapping.raw();
}

bool audio_player::is_playing() const {
    return impl_ptr<impl>()->_is_playing;
}

frame_index_t audio_player::play_frame() const {
    return impl_ptr<impl>()->_play_frame;
}
