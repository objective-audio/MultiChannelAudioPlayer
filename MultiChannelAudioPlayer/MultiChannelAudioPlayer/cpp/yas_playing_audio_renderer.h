//
//  yas_playing_audio_renderer.h
//

#pragma once

#include "yas_base.h"

namespace yas::playing {
struct audio_renderer : base {
    class impl;

    audio_renderer();
    audio_renderer(std::nullptr_t);
};
}  // namespace yas::playing
