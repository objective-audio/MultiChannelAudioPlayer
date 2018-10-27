//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include "yas_audio_format.h"

namespace yas::playing {
struct audio_channel_buffer : base {
    class impl;

    audio_channel_buffer(audio::format const &format);
};
}  // namespace yas::playing
