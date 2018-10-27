//
//  yas_playing_audio_player.mm
//

#include "yas_playing_audio_player.h"

using namespace yas;
using namespace yas::playing;

struct audio_player::impl : base::impl {
    audio::format _format;
    url const _root_url;
    operation_queue _queue;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url) {
    }
};

audio_player::audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url)) {
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

void audio_player::reload(int64_t const ch_idx, int64_t const sec_idx) {
#warning
}
