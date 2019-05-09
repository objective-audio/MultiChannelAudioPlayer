//
//  yas_playing_types.h
//

#pragma once

#include <processing/yas_processing_types.h>

namespace yas::playing {
using fragment_index_t = int64_t;
using frame_index_t = proc::frame_index_t;
using length_t = proc::length_t;
using sample_rate_t = proc::sample_rate_t;

enum queue_priority : std::size_t {
    playing = 0,
    timeline = 1,
    exporting = 2,
};

std::size_t const queue_priority_count = 3;
}  // namespace yas::playing
