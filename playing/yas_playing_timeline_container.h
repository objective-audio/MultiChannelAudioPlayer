//
//  yas_playing_timeline_container.h
//

#pragma once

#include <processing/yas_processing_timeline.h>

namespace yas::playing {
struct timeline_container {
    std::string const identifier;
    proc::sample_rate_t const sample_rate;
    proc::timeline const timeline{nullptr};
};
}  // namespace yas::playing
