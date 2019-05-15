//
//  yas_playing_signal_file.h
//

#pragma once

#include <string>

namespace yas::playing {
struct signal_file {
    signal_file(std::string const &path);

   private:
    std::string const path;
};
}  // namespace yas::playing
