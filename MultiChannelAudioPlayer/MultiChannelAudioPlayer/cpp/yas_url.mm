//
//  yas_path_utils.mm
//

#include "yas_url.h"
#include <Foundation/Foundation.h>
#include "yas_cf_utils.h"
#include "yas_objc_ptr.h"

using namespace yas;

struct url::impl : base::impl {
    objc_ptr<NSURL *> _url;

    impl(objc_ptr<NSURL *> &&url) : _url(std::move(url)) {
    }

    impl(std::string const &str)
        : _url(make_objc_ptr([[NSURL alloc] initWithString:(__bridge NSString *)to_cf_object(str)])) {
    }
};

url::url(std::string const &str) : base(std::make_shared<impl>(str)) {
}

url::url(std::shared_ptr<impl> &&impl) : base(std::move(impl)) {
}

url url::file_url(std::string const &str) {
    auto url = make_objc_ptr([[NSURL alloc] initFileURLWithPath:(__bridge NSString *)to_cf_object(str)]);
    return yas::url{std::make_shared<impl>(std::move(url))};
}

std::string url::path() const {
    return to_string((__bridge CFStringRef)(impl_ptr<impl>()->_url.object().path));
}

CFURLRef url::cf_url() const {
    return (__bridge CFURLRef)impl_ptr<impl>()->_url.object();
}

url url::appending(std::string const &str) const {
    auto url = make_objc_ptr<NSURL *>([=]() {
        return [impl_ptr<impl>()->_url.object() URLByAppendingPathComponent:(__bridge NSString *)to_cf_object(str)];
    });
    return yas::url{std::make_shared<impl>(std::move(url))};
}

#pragma mark -

std::string yas::to_string(url const &url) {
    return url.path();
}

#pragma mark -

std::ostream &operator<<(std::ostream &os, url const &url) {
    os << url.path();
    return os;
}
