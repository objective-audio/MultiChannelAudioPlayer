//
//  yas_system_url.mm
//

#include "yas_system_url.h"
#include <Foundation/Foundation.h>
#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"
#include "yas_url.h"

using namespace yas;

namespace yas {
static NSSearchPathDirectory to_search_path_directory(system_url::dir const dir) {
    switch (dir) {
        case system_url::dir::document:
            return NSDocumentDirectory;
        case system_url::dir::caches:
            return NSCachesDirectory;
        default:
            throw std::invalid_argument("invalid directory.");
    }
}
}

url system_url::directory_url(dir const dir) {
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
