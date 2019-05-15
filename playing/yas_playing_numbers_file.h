//
//  yas_playing_numbers_file.h
//

#pragma once

#include <string>

namespace yas::playing {
struct numbers_file {
    numbers_file(std::string const &);

   private:
    std::string const path;
};
}  // namespace yas::playing
