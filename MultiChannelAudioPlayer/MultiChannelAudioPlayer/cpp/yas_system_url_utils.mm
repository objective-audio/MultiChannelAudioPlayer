//
//  yas_system_url.mm
//

#include "yas_system_url_utils.h"
#include <Foundation/Foundation.h>
#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"

using namespace yas;

/*
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
 application_scripts,
 item_replacement,
 all_applications,
 all_libraries,
 */
namespace yas {
static NSSearchPathDirectory to_search_path_directory(system_url_utils::dir const dir) {
    switch (dir) {
        case system_url_utils::dir::application:
        case system_url_utils::dir::demo_application:
        case system_url_utils::dir::admin_application:
        case system_url_utils::dir::library:
        case system_url_utils::dir::developer:
        case system_url_utils::dir::user:
        case system_url_utils::dir::documentation:
        case system_url_utils::dir::document:
            return NSDocumentDirectory;
        case system_url_utils::dir::core_service:
        case system_url_utils::dir::autosaved_information:
        case system_url_utils::dir::desktop:
        case system_url_utils::dir::caches:
            return NSCachesDirectory;
        case system_url_utils::dir::application_support:
        case system_url_utils::dir::downloads:
            case system_url_utils::dir::
//        default:
//            throw std::invalid_argument("invalid directory.");
    }
}
}

url system_url_utils::directory_url(dir const dir) {
    auto path = make_objc_ptr<NSString *>([&dir] {
        switch (dir) {
            case dir::temporary:
                return NSTemporaryDirectory();
            default:
                return NSSearchPathForDirectoriesInDomains(to_search_path_directory(dir), NSUserDomainMask, YES)[0];
        }
    });
    return url::file_url(to_string((__bridge CFStringRef)path.object()));
}
