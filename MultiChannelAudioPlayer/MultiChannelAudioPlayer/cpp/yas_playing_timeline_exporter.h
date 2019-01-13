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

    timeline_exporter(url const &root_url, operation_queue queue);
    timeline_exporter(std::nullptr_t);

    void set_timeline(proc::timeline);
};
}  // namespace yas::playing
