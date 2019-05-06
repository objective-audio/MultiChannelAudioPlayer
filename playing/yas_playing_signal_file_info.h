//
//  yas_playing_signal_file_info.h
//

#pragma once

#include <processing/yas_processing_time.h>

namespace yas::playing {
struct signal_file_info {
    proc::time::range const range;
    std::type_info const &sample_type;

    signal_file_info(proc::time::range const &, std::type_info const &);

    std::string file_name() const;
};
}  // namespace yas::playing
