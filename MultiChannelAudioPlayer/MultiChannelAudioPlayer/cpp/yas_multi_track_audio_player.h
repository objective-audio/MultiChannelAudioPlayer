//
//  yas_multi_track_audio_player.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::multi_track {
struct audio_player : base {
    class impl;

    audio_player();
};
}  // namespace yas::multi_track
