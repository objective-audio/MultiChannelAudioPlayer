//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"
#include "yas_chaining.h"
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url, uint32_t const ch_count)
        : _root_url(root_url), _sample_rate(sample_rate), _pcm_format(pcm_format), _ch_count(ch_count) {
        this->_setup_chaining();
    }

    void set_playing(bool is_playing) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_is_playing = is_playing;
#warning todo engineの再生停止をする？
    }

    void seek(int64_t const play_frame) {
        uint32_t const file_length = this->_file_length();
        int64_t const top_file_idx = math::floor_int(play_frame, file_length) / file_length;

        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_play_frame = play_frame;

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
    url const _root_url;

    chaining::holder<double> _sample_rate{0.0};
    chaining::holder<audio::pcm_format> _pcm_format{audio::pcm_format::int16};
    chaining::holder<uint32_t> _ch_count{uint32_t(0)};
    chaining::holder<std::optional<audio::format>> _format{nullptr};
    chaining::observer_pool _pool;

    // 以下、要ロック
    int64_t _play_frame = 0;
    bool _is_playing = false;
    operation_queue _queue;
    std::vector<audio_circular_buffer::ptr> _circular_buffers;

    std::recursive_mutex _mutex;

    void _setup_chaining() {
        auto weak_player = to_weak(cast<audio_player>());

        this->_pool +=
            this->_sample_rate.chain().combine(this->_pcm_format.chain())
                .to([](std::pair<double, audio::pcm_format> const &pair) {
                    if (pair.first > 0.0) {
                        return std::make_optional(audio::format{audio::format::args{.sample_rate = pair.first,
                                                                                    .channel_count = 1,
                                                                                    .pcm_format = pair.second,
                                                                                    .interleaved = false}});
                    }
                    return std::optional<audio::format>{std::nullopt};
                })
                .receive(this->_format.receiver())
                .sync();

#warning todo formatとch_countをcombineしてバッファを更新する
        auto ch_count_flow = this->_ch_count.chain().to_null();

        this->_pool += this->_format.chain()
                           .perform([weak_player](auto const &) {
                               if (auto player = weak_player.lock()) {
                                   return player.impl_ptr<impl>()->_update_circular_buffers();
                               }
                           })
                           .sync();
    }

    uint32_t _file_length() {
        if (auto const &format = this->_format.value(); format) {
            return static_cast<uint32_t>(format->sample_rate());
        } else {
            return 0;
        }
    }

    std::optional<audio::format> _to_format() {
        double const sample_rate = this->_sample_rate.value();
        audio::pcm_format const pcm_format = this->_pcm_format.value();
        uint32_t const ch_count = this->_ch_count.value();

        if (sample_rate > 0.0 && ch_count > 0) {
            return audio::format{audio::format::args{
                .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}};
        } else {
            return std::nullopt;
        }
    }

    void _update_circular_buffers() {
        if (this->_format.value()) {
            audio::format const &format = *this->_format.value();
            uint32_t const ch_count = this->_ch_count.value();

            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            auto each = make_fast_each(ch_count);
            while (yas_each_next(each)) {
                auto const ch_url = url_utils::channel_url(this->_root_url, yas_each_index(each));
                auto buffer = make_audio_circular_buffer(format, 3, ch_url, this->_queue);
                this->_circular_buffers.push_back(std::move(buffer));
            }
        } else {
            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            this->_circular_buffers.clear();
        }
    }
};

audio_player::audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                           uint32_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url, ch_count)) {
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
