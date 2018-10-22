//
//  yas_system_url.h
//

#pragma once

#include <string>

namespace yas {
class url;
}

namespace yas::system_url {
enum class dir {
    document,
    caches,
    temporary,
};

url directory_url(dir const);
}  // namespace yas::system_url
