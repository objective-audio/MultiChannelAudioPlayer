//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    audio_coordinator(url root_url);
    audio_coordinator(std::nullptr_t);
};
}  // namespace yas::playing
