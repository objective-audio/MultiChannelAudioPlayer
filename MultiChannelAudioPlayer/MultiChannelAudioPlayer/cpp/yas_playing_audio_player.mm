//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"
#include "yas_fast_each.h"
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    audio::format const _format;
    url const _root_url;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url, uint32_t const ch_count)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url) {
        auto each = make_fast_each(ch_count);
        while (yas_each_next(each)) {
            auto const ch_url = url_utils::channel_url(this->_root_url, yas_each_index(each));
            audio_circular_buffer buffer{this->_format, 3, ch_url, this->_queue};
            this->_buffers.push_back(std::move(buffer));
        }
    }

   private:
    int64_t _current_frame = 0;
    operation_queue _queue;
    std::vector<audio_circular_buffer> _buffers;

    std::recursive_mutex _mutex;
};

audio_player::audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                           uint32_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url, ch_count)) {
}

void audio_player::play() {
#warning
}

void audio_player::stop() {
#warning
}

void audio_player::seek(int64_t const frame_idx) {
#warning
}

void audio_player::reload(int64_t const ch_idx, int64_t const file_idx) {
#warning
}
