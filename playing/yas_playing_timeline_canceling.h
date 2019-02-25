//
//  yas_playing_timeline_canceling.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_protocol.h>
#include <processing/yas_processing_umbrella.h>

namespace yas::playing {
struct timeline_cancel_matcher_id : base {
    class impl;

    timeline_cancel_matcher_id(proc::track_index_t const trk_idx, proc::time::range const &range);
    timeline_cancel_matcher_id(proc::track_index_t const trk_idx);
    timeline_cancel_matcher_id();
    timeline_cancel_matcher_id(std::nullptr_t);
};

struct timeline_cancel_request : protocol {
    struct impl : protocol::impl {
        virtual bool is_match(timeline_cancel_matcher_id::impl const &) const = 0;
    };
};

struct timeline_track_cancel_request_id : base {
    class impl;

    explicit timeline_track_cancel_request_id(proc::track_index_t const trk_idx);
    timeline_track_cancel_request_id(std::nullptr_t);
};

struct timeline_range_cancel_request_id : base {
    class impl;

    explicit timeline_range_cancel_request_id(proc::time::range const &range);
    timeline_range_cancel_request_id(std::nullptr_t);
};
}  // namespace yas::playing
