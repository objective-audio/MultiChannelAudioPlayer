//
//  yas_playing_timeline_container.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <processing/yas_processing_timeline.h>

namespace yas::playing {
struct timeline_container : base {
    class impl;

    timeline_container(std::string identifier, proc::sample_rate_t const sample_rate, proc::timeline timeline);
    explicit timeline_container(proc::sample_rate_t const sample_rate);
    timeline_container(std::nullptr_t);

    std::string const &identifier() const;
    proc::sample_rate_t const &sample_rate() const;
    proc::timeline const &timeline() const;
};
}  // namespace yas::playing
