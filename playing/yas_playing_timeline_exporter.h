//
//  yas_playing_timeline_exporter.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_operation.h>
#include <cpp_utils/yas_result.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_timeline.h>

namespace yas::playing {
struct timeline_exporter : base {
    class impl;

    enum event_type {
        reset,
        export_began,
        export_ended,
        export_failed,
    };

    enum error_type {
        remove_fragment_failed,
        create_directory_failed,
        open_signal_stream_failed,
        open_number_stream_failed,
        get_content_paths_failed,
        sync_source_not_found,
    };

    struct event {
        event_type const type;
        std::optional<proc::time::range> const range;
    };

    struct error {
        error_type const type;
        std::optional<proc::time::range> const range;
    };

    using export_result_t = result<event, error>;
    using export_result_f = std::function<void(export_result_t const &)>;

    timeline_exporter(url const &root_url, operation_queue, proc::sample_rate_t const);
    timeline_exporter(std::nullptr_t);

    void set_timeline(proc::timeline);
    void set_sample_rate(proc::sample_rate_t const);
    void set_result_handler(export_result_f);
};
}  // namespace yas::playing
