//
//  yas_playing_audio_types.h
//

#pragma once

namespace yas::playing {
enum audio_queue_priority : std::size_t {
    player = 0,
    exporter = 1,
};

std::size_t const audio_queue_priority_count = 2;
}  // namespace yas::playing
