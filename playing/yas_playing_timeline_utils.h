//
//  yas_playing_timeline_utils.h
//

#pragma once

#include <processing/yas_processing_time.h>

namespace yas::playing::timeline_utils {
[[nodiscard]] proc::time::range fragment_range(proc::time::range const &, proc::sample_rate_t const);
}
