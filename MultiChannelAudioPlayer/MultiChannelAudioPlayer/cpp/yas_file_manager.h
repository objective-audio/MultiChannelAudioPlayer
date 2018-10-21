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

    enum class file_kind {
        file,
        directory,
    };

    enum class remove_error {
        remove_failed,
    };

    using create_dir_result_t = result<std::nullptr_t, create_dir_error>;
    using exists_result_t = result<file_kind, std::nullptr_t>;
    using remove_result_t = result<std::nullptr_t, remove_error>;

    [[nodiscard]] static create_dir_result_t create_directory_if_not_exists(std::string const &path);
    [[nodiscard]] static exists_result_t file_exists(std::string const &path);
    static remove_result_t remove_file(std::string const &path);
};

std::string to_string(file_manager::create_dir_error const &);
}  // namespace yas
