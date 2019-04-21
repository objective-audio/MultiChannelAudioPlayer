//
//  yas_playing_timeline_utils.cpp
//

#include "yas_playing_timeline_utils.h"
#include "yas_playing_math.h"

using namespace yas;
using namespace yas::playing;

proc::time::range timeline_utils::fragment_range(proc::time::range const &range,
                                                 proc::sample_rate_t const sample_rate) {
    auto const frame = math::floor_int(range.frame, sample_rate);
    auto const next_frame = math::ceil_int(range.next_frame(), sample_rate);
    return proc::time::range{frame, static_cast<proc::length_t>(next_frame - frame)};
}
