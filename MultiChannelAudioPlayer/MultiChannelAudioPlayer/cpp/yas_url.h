//
//  yas_path_utils.h
//

#pragma once

#include <string>
#include "yas_base.h"

namespace yas {
struct url : base {
    class impl;

    url(std::string const &str);

    std::string path() const;

    url appending(std::string const &);
};
}  // namespace yas
