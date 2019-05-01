//
//  yas_playing_timeline_canceling.cpp
//

#include "yas_playing_timeline_canceling.h"

using namespace yas;
using namespace yas::playing;

#pragma mark - cancel_id

struct timeline_cancel_matcher::impl : base::impl {
    std::optional<proc::time::range> const range;

    impl(std::optional<proc::time::range> &&range) : range(std::move(range)) {
    }

    bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<timeline_cancel_request::impl>(rhs)) {
            return casted_rhs->is_match(*this);
        }
        return false;
    }
};

timeline_cancel_matcher::timeline_cancel_matcher(proc::time::range const &range)
    : base(std::make_shared<impl>(std::make_optional(range))) {
}

timeline_cancel_matcher::timeline_cancel_matcher() : base(std::make_shared<impl>(std::nullopt)) {
}

timeline_cancel_matcher::timeline_cancel_matcher(std::nullptr_t) : base(nullptr) {
}

#pragma mark - range_cancel_request

struct timeline_range_cancel_request::impl : base::impl, timeline_cancel_request::impl {
    proc::time::range const range;

    impl(proc::time::range const &range) : range(range) {
    }

    bool is_match(timeline_cancel_matcher::impl const &matcher_impl) const override {
        if (matcher_impl.range.has_value()) {
            return this->range.is_contain(*matcher_impl.range);
        } else {
            return false;
        }
    }

    bool is_equal(std::shared_ptr<base::impl> const &rhs) const override {
        if (auto casted_rhs = std::dynamic_pointer_cast<timeline_cancel_matcher::impl>(rhs)) {
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
