//
//  yas_playing_audio_buffers.cpp
//

#include "yas_playing_audio_buffers.h"

using namespace yas;
using namespace yas::playing;

struct audio_play_buffers::impl : base::impl {
    std::size_t const _ch_count;

    impl(double const sample_rate, audio::pcm_format const pcm_format, std::size_t const ch_count)
        : _ch_count(ch_count) {
    }
};

audio_play_buffers::audio_play_buffers(double const sample_rate, audio::pcm_format const pcm_format,
                                       std::size_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, ch_count)) {
}
