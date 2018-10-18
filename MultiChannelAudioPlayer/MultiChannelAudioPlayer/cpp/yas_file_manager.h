//
//  yas_file_manager.h
//

#pragma once

#include <string>
#include "yas_result.h"

namespace yas {
struct file_manager {
    enum class create_dir_error {
        create_failed,
        file_exists,
    };

    using create_dir_result_t = result<std::nullptr_t, create_dir_error>;

    static create_dir_result_t create_directory_if_not_exists(std::string const &path);
};

std::string to_string(file_manager::create_dir_error const &);
}  // namespace yas
