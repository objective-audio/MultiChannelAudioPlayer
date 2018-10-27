//
//  yas_playing_audio_buffers.cpp
//

#include "yas_playing_audio_play_buffer_manager.h"

using namespace yas;
using namespace yas::playing;

struct audio_play_buffer_manager::impl : base::impl {
    std::size_t const _ch_count;
    audio::format const _format;

    impl(double const sample_rate, audio::pcm_format const pcm_format, std::size_t const ch_count)
        : _ch_count(ch_count),
          _format({.sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}) {
    }
};

audio_play_buffer_manager::audio_play_buffer_manager(double const sample_rate, audio::pcm_format const pcm_format,
                                                     std::size_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, ch_count)) {
}
