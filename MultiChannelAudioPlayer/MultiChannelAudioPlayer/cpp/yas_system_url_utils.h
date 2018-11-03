//
//  yas_system_url_utils.h
//

#pragma once

#include <string>

namespace yas {
class url;
}

namespace yas::system_url_utils {
enum class dir {
    document,
    caches,
    temporary,
};

[[nodiscard]] url directory_url(dir const);
}  // namespace yas::system_url_utils
