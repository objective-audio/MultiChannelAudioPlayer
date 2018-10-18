//
//  yas_path_utils.h
//

#pragma once

#include <string>

namespace yas {
struct path {
    path(std::string const &);

    std::string str() const;

    path append(std::string const &);

   private:
    std::string _str;
};
}  // namespace yas
