//
//  yas_playing_timeline_canceling.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <processing/yas_processing_umbrella.h>

namespace yas::playing {
struct timeline_canceling_matcher : base {
    class impl;

    timeline_canceling_matcher(proc::track_index_t const trk_idx, proc::time::range const &range);
    timeline_canceling_matcher(std::nullptr_t);
};

struct timeline_canceling_request : base {
    class impl;

    timeline_canceling_request();
    timeline_canceling_request(std::nullptr_t);
};
}  // namespace yas::playing
