//
//  yas_system_path.h
//

#pragma once

#include <string>

namespace yas::system_path {
enum class dir {
    document,
    caches,
    temporary,
};

std::string directory_path(dir const);
}  // namespace yas::system_path
