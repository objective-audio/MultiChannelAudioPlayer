//
//  yas_multi_track_signal_exporter.h
//

#pragma once

#include <string>
#include "yas_base.h"
#include "yas_processing.h"

namespace yas::multi_track {
struct signal_exporter : base {
    class impl;

    signal_exporter(std::string const &root_path);

    void export_file(uint32_t const trk_idx, proc::time::range const &range,
                     std::function<void(proc::time::range const &range)>);
};
}  // namespace yas::multi_track
