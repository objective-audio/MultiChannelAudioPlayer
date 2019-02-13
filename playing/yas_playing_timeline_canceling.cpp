//
//  yas_playing_timeline_canceling.cpp
//

#include "yas_playing_timeline_canceling.h"

#warning todo

using namespace yas;
using namespace yas::playing;

struct timeline_canceling_matcher::impl : base::impl {
    proc::track_index_t const trk_idx;
    proc::time::range const range;

    impl(proc::track_index_t const trk_idx, proc::time::range const &range) : trk_idx(trk_idx), range(range) {
    }
};

timeline_canceling_matcher::timeline_canceling_matcher(proc::track_index_t const trk_idx,
                                                       proc::time::range const &range)
    : base(std::make_shared<impl>(trk_idx, range)) {
}

timeline_canceling_matcher::timeline_canceling_matcher(std::nullptr_t) : base(nullptr) {
}

struct timeline_canceling_request::impl : base::impl {};

timeline_canceling_request::timeline_canceling_request() : base(std::make_shared<impl>()) {
}

timeline_canceling_request::timeline_canceling_request(std::nullptr_t) : base(nullptr) {
}
