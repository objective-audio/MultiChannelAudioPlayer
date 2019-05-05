//
//  yas_playing_types.h
//

#pragma once

#include <audio/yas_audio_format.h>

namespace yas::playing {
enum queue_priority : std::size_t {
    playing = 0,
    timeline = 1,
    exporting = 2,
};

std::size_t const queue_priority_count = 3;
}  // namespace yas::playing
