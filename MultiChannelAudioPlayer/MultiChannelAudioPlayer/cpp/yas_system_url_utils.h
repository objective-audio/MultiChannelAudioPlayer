//
//  yas_system_url_utils.h
//

#pragma once

#include <string>
#include "yas_url.h"

namespace yas::system_url_utils {
enum class dir {
    application,
    demo_application,
    admin_application,
    library,
    developer,
    user,
    documentation,
    document,
    core_service,
    autosaved_information,
    desktop,
    caches,
    application_support,
    downloads,
    input_methods,
    movies,
    music,
    pictures,
    printer_description,
    shared_public,
    preference_panes,
#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)
    application_scripts,
#endif
    item_replacement,
    all_applications,
    all_libraries,

    temporary,
    home,
    open_step_root,
};

[[nodiscard]] url directory_url(dir const);
}  // namespace yas::system_url_utils
