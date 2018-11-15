//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"
#include <atomic>
#include "yas_chaining.h"
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_audio_utils.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    url const _root_url;
    // ロックここから
    std::atomic<int64_t> _play_frame = 0;
    std::atomic<bool> _is_playing = false;
    // ロックここまで

    impl(audio_renderable &&renderable, url const &root_url) : _root_url(root_url), _renderable(std::move(renderable)) {
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
        uint32_t const file_length = this->_file_length();

        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_play_frame = play_frame;

        if (file_length == 0) {
            return;
        }

        int64_t const top_file_idx = math::floor_int(play_frame, file_length) / file_length;

        for (auto &buffer : this->_circular_buffers) {
            buffer->reload_all(top_file_idx);
        }
    }

    void reload(int64_t const ch_idx, int64_t const file_idx) {
        if (this->_circular_buffers.size() <= ch_idx) {
            return;
        }

        auto &buffer = this->_circular_buffers.at(ch_idx);
        buffer->reload(file_idx);
    }

   private:
    chaining::observer_pool _pool;

    operation_queue _queue;
    audio_renderable _renderable;

    // ロックここから
    std::vector<audio_circular_buffer::ptr> _circular_buffers;
    chaining::holder<std::optional<audio::format>> _format{std::nullopt};
    // ロックここまで
    std::recursive_mutex _mutex;

    // render only
    audio::pcm_buffer _read_buffer{nullptr};

    void _setup_chaining(audio_player &player) {
        auto weak_player = to_weak(player);

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
                .receive(this->_format.receiver())
                .sync();

        this->_pool += this->_format.chain()
                           .combine(this->_renderable.chain_channel_count())
                           .perform([weak_player](auto const &pair) {
                               if (auto player = weak_player.lock()) {
                                   player.impl_ptr<impl>()->_update_circular_buffers(pair);
                               }
                           })
                           .sync();
    }

    void _setup_rendering_handler(audio_player &player) {
        auto weak_player = to_weak(player);

        this->_renderable.set_rendering_handler([weak_player](std::vector<audio::pcm_buffer> &out_buffers) {
            if (out_buffers.size() == 0) {
                return;
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
            uint32_t const out_length = out_buffers.at(0).frame_length();
            int64_t const next_frame = play_frame + out_length;
            player_impl->_play_frame = next_frame;
            uint32_t const file_length = player_impl->_file_length();
            auto read_buffer = player_impl->_get_or_create_read_buffer(out_buffers.at(0).format(), out_length);

            while (play_frame < next_frame) {
                auto const info = audio_utils::processing_info{play_frame, next_frame, file_length};
                uint32_t const to_frame = uint32_t(play_frame - begin_play_frame);

                auto each = make_fast_each(out_buffers.size());
                while (yas_each_next(each)) {
                    auto const &idx = yas_each_index(each);

                    if (player_impl->_circular_buffers.size() <= idx) {
                        break;
                    }

                    read_buffer.clear();
                    read_buffer.set_frame_length(info.length);

                    auto &circular_buffer = player_impl->_circular_buffers.at(idx);
                    circular_buffer->read_into_buffer(read_buffer, play_frame);

#warning resultを見る？
                    out_buffers.at(idx).copy_from(read_buffer, 0, to_frame, info.length);

                    if (info.next_file_idx.has_value()) {
                        circular_buffer->rotate_buffer(*info.next_file_idx);
                    }
                }

                play_frame += info.length;
            }
        });
    }

    uint32_t _file_length() {
        if (auto const &format = this->_format.value(); format) {
            return static_cast<uint32_t>(format->sample_rate());
        } else {
            return 0;
        }
    }

    void _update_circular_buffers(std::pair<std::optional<audio::format>, uint32_t> const &pair) {
        auto const &[format, ch_count] = pair;

        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_circular_buffers.clear();

        if (format && ch_count > 0) {
            auto each = make_fast_each(ch_count);
            while (yas_each_next(each)) {
                auto const ch_url = url_utils::channel_url(this->_root_url, yas_each_index(each));
                auto buffer = make_audio_circular_buffer(*format, 3, ch_url, this->_queue);

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
};

audio_player::audio_player(audio_renderable renderable, url const &root_url)
    : base(std::make_shared<impl>(std::move(renderable), root_url)) {
    impl_ptr<impl>()->prepare(*this);
}

audio_player::audio_player(std::nullptr_t) : base(nullptr) {
}

void audio_player::set_playing(bool const is_playing) {
    impl_ptr<impl>()->set_playing(is_playing);
}

void audio_player::seek(int64_t const play_frame) {
    impl_ptr<impl>()->seek(play_frame);
}

void audio_player::reload(int64_t const ch_idx, int64_t const file_idx) {
    impl_ptr<impl>()->reload(ch_idx, file_idx);
}

url audio_player::root_url() const {
    return impl_ptr<impl>()->_root_url;
}

bool audio_player::is_playing() const {
    return impl_ptr<impl>()->_is_playing;
}

int64_t audio_player::play_frame() const {
    return impl_ptr<impl>()->_play_frame;
}
