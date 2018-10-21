//
//  yas_system_path.mm
//

#include "yas_system_path.h"
#include <Foundation/Foundation.h>
#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"

using namespace yas;

namespace yas {
static NSSearchPathDirectory to_search_path_directory(system_path::dir const dir) {
    switch (dir) {
        case system_path::dir::document:
            return NSDocumentDirectory;
        case system_path::dir::caches:
            return NSCachesDirectory;
        default:
            throw std::invalid_argument("invalid directory.");
    }
}
}

std::string system_path::directory_path(dir const dir) {
    auto path = make_objc_ptr<NSString *>([&dir] {
        switch (dir) {
            case dir::temporary:
                return NSTemporaryDirectory();
            default:
                return NSSearchPathForDirectoriesInDomains(to_search_path_directory(dir), NSUserDomainMask, YES)[0];
        }
    });
    return to_string((__bridge CFStringRef)path.object());
}
