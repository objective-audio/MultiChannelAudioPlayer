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

    enum class kind {
        file,
        directory,
    };

    using create_dir_result_t = result<std::nullptr_t, create_dir_error>;
    using exists_result_t = result<kind, std::nullptr_t>;

    static create_dir_result_t create_directory_if_not_exists(std::string const &path);
    static exists_result_t file_exists(std::string const &path);
};

std::string to_string(file_manager::create_dir_error const &);
}  // namespace yas
