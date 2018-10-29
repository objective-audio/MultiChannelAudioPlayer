//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include "yas_audio_pcm_buffer.h"

namespace yas::playing {
struct audio_circular_buffer : base {
    class impl;

    audio_circular_buffer(audio::format const &format, std::size_t const count, std::size_t const ch_idx);

    void read(audio::pcm_buffer &out_buffer);
};
}  // namespace yas::playing
