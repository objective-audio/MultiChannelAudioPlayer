//
//  yas_playing_timeline_canceling.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_protocol.h>
#include <processing/yas_processing_umbrella.h>

namespace yas::playing {
struct timeline_cancel_matcher : base {
    class impl;

    timeline_cancel_matcher(proc::time::range const &);
    timeline_cancel_matcher();
    timeline_cancel_matcher(std::nullptr_t);
};

struct timeline_cancel_request : protocol {
    struct impl : protocol::impl {
        virtual bool is_match(timeline_cancel_matcher::impl const &) const = 0;
    };
};

// requestの範囲に完全に含まれていたらキャンセルさせる
struct timeline_range_cancel_request : base {
    class impl;

    explicit timeline_range_cancel_request(proc::time::range const &range);
    timeline_range_cancel_request(std::nullptr_t);
};
}  // namespace yas::playing
