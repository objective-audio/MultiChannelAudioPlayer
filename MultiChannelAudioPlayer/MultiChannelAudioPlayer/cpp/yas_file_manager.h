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

    enum class content_kind {
        file,
        directory,
    };

    enum class remove_file_error {
        remove_failed,
    };

    enum class remove_files_error {
        not_directory,
        remove_failed,
        find_contents_failed,
    };

    using create_dir_result_t = result<std::nullptr_t, create_dir_error>;
    using exists_result_t = result<content_kind, std::nullptr_t>;
    using remove_result_t = result<std::nullptr_t, remove_file_error>;
    using remove_files_result_t = result<std::nullptr_t, remove_files_error>;

    [[nodiscard]] static create_dir_result_t create_directory_if_not_exists(std::string const &path);
    [[nodiscard]] static exists_result_t file_exists(std::string const &path);
    static remove_result_t remove_file(std::string const &path);
    static remove_files_result_t remove_files_in_directory(std::string const &dir_path);
};

std::string to_string(file_manager::create_dir_error const &);
}  // namespace yas
