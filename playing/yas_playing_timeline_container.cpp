//
//  yas_playing_timeline_container.cpp
//

#include "yas_playing_timeline_container.h"

using namespace yas;
using namespace yas::playing;

struct timeline_container::impl : base::impl {
    std::string const identifier;
    proc::sample_rate_t const sample_rate;
    proc::timeline const timeline;

    impl(std::string &&identifier, proc::sample_rate_t const sample_rate, proc::timeline &&timeline)
        : identifier(std::move(identifier)), sample_rate(sample_rate), timeline(std::move(timeline)) {
    }

    impl(proc::sample_rate_t const sample_rate) : sample_rate(sample_rate), timeline(nullptr) {
    }
};

timeline_container::timeline_container(std::string identifier, proc::sample_rate_t const sample_rate,
                                       proc::timeline timeline)
    : base(std::make_shared<impl>(std::move(identifier), sample_rate, std::move(timeline))) {
}

timeline_container::timeline_container(proc::sample_rate_t const sample_rate)
    : base(std::make_shared<impl>(sample_rate)) {
}

timeline_container::timeline_container(std::nullptr_t) : base(nullptr) {
}

std::string const &timeline_container::identifier() const {
    return this->impl_ptr<impl>()->identifier;
}

proc::sample_rate_t const &timeline_container::sample_rate() const {
    return this->impl_ptr<impl>()->sample_rate;
}

proc::timeline const &timeline_container::timeline() const {
    return this->impl_ptr<impl>()->timeline;
}
