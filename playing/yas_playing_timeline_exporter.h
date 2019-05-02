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

    enum method {
        reset,
        export_began,
        export_ended,
        export_failed,
    };

    enum error {
        remove_fragment_failed,
        create_directory_failed,
        open_signal_stream_failed,
        open_number_stream_failed,
        get_content_paths_failed,
        sync_source_not_found,
    };

    using result_t = result<method, error>;

    struct event {
        result_t const result;
        std::optional<proc::time::range> const range;
    };

    using event_f = std::function<void(event const &)>;

    timeline_exporter(std::string const &root_path, operation_queue, proc::sample_rate_t const);
    timeline_exporter(std::nullptr_t);

    void set_timeline(proc::timeline);
    void set_sample_rate(proc::sample_rate_t const);
    void set_result_handler(event_f);
};
}  // namespace yas::playing
