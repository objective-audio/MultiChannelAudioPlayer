//
//  yas_playing_audio_buffers.h
//

#pragma once

#include "yas_audio.h"

namespace yas::playing {
struct audio_play_buffer_manager : base {
    class impl;

    audio_play_buffer_manager(double const sample_rate, audio::pcm_format const pcm_format, std::size_t const ch_count);
};
}  // namespace yas::playing
