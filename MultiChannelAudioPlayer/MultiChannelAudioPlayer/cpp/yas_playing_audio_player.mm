//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    audio::format const _format;
    uint32_t const _file_length;
    url const _root_url;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url, uint32_t const ch_count)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url),
          _file_length(static_cast<uint32_t>(sample_rate)) {
        auto each = make_fast_each(ch_count);
        while (yas_each_next(each)) {
            auto const ch_url = url_utils::channel_url(this->_root_url, yas_each_index(each));
            audio_circular_buffer buffer{this->_format, 3, ch_url, this->_queue};
            this->_buffers.push_back(std::move(buffer));
        }
    }

    void set_playing(bool is_playing) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_is_playing = is_playing;
#warning todo engineの再生停止をする？
    }

    void seek(int64_t const play_frame) {
        std::lock_guard<std::recursive_mutex> lock(this->_mutex);

        this->_play_frame = play_frame;

        int64_t const top_file_idx = math::floor_int(play_frame, this->_file_length) / this->_file_length;

        for (auto &buffer : this->_buffers) {
            buffer.reload_all(top_file_idx);
        }
#warning todo バッファのリロード
    }

    void reload(int64_t const ch_idx, int64_t const file_idx) {
        if (this->_buffers.size() <= ch_idx) {
            return;
        }

        auto &buffer = this->_buffers.at(ch_idx);
        buffer.reload(file_idx);
    }

   private:
    int64_t _play_frame = 0;
    bool _is_playing = false;
    operation_queue _queue;
    std::vector<audio_circular_buffer> _buffers;

    std::recursive_mutex _mutex;
};

audio_player::audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                           uint32_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url, ch_count)) {
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
