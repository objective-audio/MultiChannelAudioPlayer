//
//  yas_playing_test_utils.h
//

#pragma once

#include "yas_file_manager.h"
#include "yas_system_url_utils.h"

namespace yas::playing_test_utils {
void remove_all_document_files() {
    auto document_url = system_url_utils::directory_url(system_url_utils::dir::document);
    file_manager::remove_files_in_directory(document_url.path());
}
}  // namespace yas::playing_test_utils
