//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include "yas_audio_format.h"

namespace yas::playing {
struct audio_circular_buffer : base {
    class impl;

    audio_circular_buffer(audio::format const &format, uint32_t const count);
};
}  // namespace yas::playing
