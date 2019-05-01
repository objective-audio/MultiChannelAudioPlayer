//
//  yas_playing_timeline_exporter.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_operation.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_timeline.h>

namespace yas::playing {
struct timeline_exporter : base {
    class impl;

    enum event_type {
        reset,
        export_began,
        export_ended,
    };

    enum error_type {
        unknown,
    };

    struct event {
        event_type const type;
        std::optional<proc::time::range> range;
    };

    timeline_exporter(url const &root_url, operation_queue, proc::sample_rate_t const);
    timeline_exporter(std::nullptr_t);

    void set_timeline(proc::timeline);
    void set_sample_rate(proc::sample_rate_t const);
};
}  // namespace yas::playing
