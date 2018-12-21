//
//  yas_playing_timeline_exporter.h
//

#pragma once

#include "yas_base.h"
#include "yas_operation.h"
#include "yas_processing_timeline.h"
#include "yas_url.h"

namespace yas::playing {
struct timeline_exporter : base {
    class impl;

    timeline_exporter(url const &root_url, operation_queue queue);
    timeline_exporter(std::nullptr_t);
};
}  // namespace yas::playing
