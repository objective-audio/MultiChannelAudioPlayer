//
//  yas_playing_timeline_exporter.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_result.h>
#include <cpp_utils/yas_task.h>
#include <processing/yas_processing_timeline.h>
#include "yas_playing_timeline_container.h"

namespace yas::playing {
struct timeline_exporter : base {
    class impl;

    enum class method {
        reset,
        export_began,
        export_ended,
    };

    enum class error {
        remove_fragment_failed,
        create_directory_failed,
        write_signal_failed,
        write_numbers_failed,
        get_content_paths_failed,
    };

    using result_t = result<method, error>;

    struct event {
        result_t const result;
        std::optional<proc::time::range> const range;
    };

    timeline_exporter(std::string const &root_path, task_queue, proc::sample_rate_t const);
    timeline_exporter(std::nullptr_t);

    void set_timeline_container(timeline_container);

    chaining::chain_unsync_t<event> event_chain() const;
};
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::timeline_exporter::method const &);
std::string to_string(playing::timeline_exporter::error const &);
};  // namespace yas
