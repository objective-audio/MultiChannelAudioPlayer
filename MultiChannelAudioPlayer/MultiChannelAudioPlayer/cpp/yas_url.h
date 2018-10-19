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
    static url file_url(std::string const &path);

    std::string path() const;

    url appending(std::string const &);

   protected:
    url(std::shared_ptr<impl> &&);
};
}  // namespace yas
