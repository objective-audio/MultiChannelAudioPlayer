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

    signal_exporter(std::string const &path);
};
}  // namespace yas::multi_track
