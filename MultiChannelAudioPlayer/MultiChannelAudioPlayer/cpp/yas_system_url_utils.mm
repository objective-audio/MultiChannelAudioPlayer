//
//  yas_system_url.mm
//

#include "yas_system_url_utils.h"
#include <Foundation/Foundation.h>
#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"

using namespace yas;

namespace yas {
static NSSearchPathDirectory to_search_path_directory(system_url_utils::dir const dir) {
    switch (dir) {
        case system_url_utils::dir::application:
            return NSApplicationDirectory;
        case system_url_utils::dir::demo_application:
            return NSDemoApplicationDirectory;
        case system_url_utils::dir::admin_application:
            return NSAdminApplicationDirectory;
        case system_url_utils::dir::library:
            return NSLibraryDirectory;
        case system_url_utils::dir::developer:
            return NSDeveloperDirectory;
        case system_url_utils::dir::user:
            return NSUserDirectory;
        case system_url_utils::dir::documentation:
            return NSDocumentationDirectory;
        case system_url_utils::dir::document:
            return NSDocumentDirectory;
        case system_url_utils::dir::core_service:
            return NSCoreServiceDirectory;
        case system_url_utils::dir::autosaved_information:
            return NSAutosavedInformationDirectory;
        case system_url_utils::dir::desktop:
            return NSDesktopDirectory;
        case system_url_utils::dir::caches:
            return NSCachesDirectory;
        case system_url_utils::dir::application_support:
            return NSApplicationSupportDirectory;
        case system_url_utils::dir::downloads:
            return NSDownloadsDirectory;
        case system_url_utils::dir::input_methods:
            return NSInputMethodsDirectory;
        case system_url_utils::dir::movies:
            return NSMoviesDirectory;
        case system_url_utils::dir::music:
            return NSMusicDirectory;
        case system_url_utils::dir::pictures:
            return NSPicturesDirectory;
        case system_url_utils::dir::printer_description:
            return NSPrinterDescriptionDirectory;
        case system_url_utils::dir::shared_public:
            return NSSharedPublicDirectory;
        case system_url_utils::dir::preference_panes:
            return NSPreferencePanesDirectory;
#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)
        case system_url_utils::dir::application_scripts:
            return NSApplicationScriptsDirectory;
#endif
        case system_url_utils::dir::item_replacement:
            return NSItemReplacementDirectory;
        case system_url_utils::dir::all_applications:
            return NSAllApplicationsDirectory;
        case system_url_utils::dir::all_libraries:
            return NSAllLibrariesDirectory;
        default:
            throw std::invalid_argument("invalid directory.");
    }
}
}

url system_url_utils::directory_url(dir const dir) {
    auto path = make_objc_ptr<NSString *>([&dir] {
        switch (dir) {
            case dir::temporary:
                return NSTemporaryDirectory();
            case dir::home:
                return NSHomeDirectory();
            case dir::open_step_root:
                return NSOpenStepRootDirectory();
            default:
                return NSSearchPathForDirectoriesInDomains(to_search_path_directory(dir), NSUserDomainMask, YES)[0];
        }
    });
    return url::file_url(to_string((__bridge CFStringRef)path.object()));
}
