//
//  yas_playing_signal_file.h
//

#pragma once

#include <processing/yas_processing_signal_event.h>
#include <processing/yas_processing_time.h>
#include <string>

namespace yas::playing {
struct signal_file {
    signal_file(std::string const &path);

    void write(proc::time::range const &range, proc::signal_event const &event);

   private:
    std::string const _path;
};
}  // namespace yas::playing
