//
//  yas_playing_types.h
//

#pragma once

#include <processing/yas_processing_types.h>

namespace yas::playing {
using channel_index_t = proc::channel_index_t;
using fragment_index_t = int64_t;
using frame_index_t = proc::frame_index_t;
using length_t = proc::length_t;
using sample_rate_t = proc::sample_rate_t;

enum sample_store_type : char {
    unknown = 0,
    f64 = 1,
    f32 = 2,
    i64 = 3,
    u64 = 4,
    i32 = 5,
    u32 = 6,
    i16 = 7,
    u16 = 8,
    i8 = 9,
    u8 = 10,
    b = 11,
};

enum queue_priority : std::size_t {
    playing = 0,
    timeline = 1,
    exporting = 2,
};

std::size_t const queue_priority_count = 3;
}  // namespace yas::playing
