//
//  yas_playing_timeline_canceling.cpp
//

#include "yas_playing_timeline_canceling.h"

using namespace yas;
using namespace yas::playing;

#pragma mark - canceling_matcher

struct timeline_cancel_id::impl : base::impl {
    proc::track_index_t const trk_idx;
    proc::time::range const range;

    impl(proc::track_index_t const trk_idx, proc::time::range const &range) : trk_idx(trk_idx), range(range) {
    }

    bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<timeline_cancel_request::impl>(rhs)) {
            return casted_rhs->is_match(*this);
        }
        return false;
    }
};

timeline_cancel_id::timeline_cancel_id(proc::track_index_t const trk_idx,
                                                       proc::time::range const &range)
    : base(std::make_shared<impl>(trk_idx, range)) {
}

timeline_cancel_id::timeline_cancel_id(std::nullptr_t) : base(nullptr) {
}

#pragma mark - track_cancel_request

struct timeline_track_cancel_request::impl : base::impl, timeline_cancel_request::impl {
    proc::track_index_t const trk_idx;

    impl(proc::track_index_t const trk_idx) : trk_idx(trk_idx) {
    }

    bool is_match(timeline_cancel_id::impl const &matcher_impl) const override {
        return matcher_impl.trk_idx == this->trk_idx;
    }

    bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<timeline_cancel_id::impl>(rhs)) {
            return this->is_match(*casted_rhs);
        }
        return false;
    }
};

timeline_track_cancel_request::timeline_track_cancel_request(proc::track_index_t const trk_idx)
    : base(std::make_shared<impl>(trk_idx)) {
}

timeline_track_cancel_request::timeline_track_cancel_request(std::nullptr_t) : base(nullptr) {
}

#pragma mark - range_cancel_request

struct timeline_range_cancel_request::impl : base::impl, timeline_cancel_request::impl {
    proc::time::range const range;

    impl(proc::time::range const &range) : range(range) {
    }

    bool is_match(timeline_cancel_id::impl const &matcher_impl) const override {
        return matcher_impl.range.is_contain(this->range);
    }

    bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<timeline_cancel_id::impl>(rhs)) {
            return this->is_match(*casted_rhs);
        }
        return false;
    }
};

timeline_range_cancel_request::timeline_range_cancel_request(proc::time::range const &range)
    : base(std::make_shared<impl>(range)) {
}

timeline_range_cancel_request::timeline_range_cancel_request(std::nullptr_t) : base(nullptr) {
}
