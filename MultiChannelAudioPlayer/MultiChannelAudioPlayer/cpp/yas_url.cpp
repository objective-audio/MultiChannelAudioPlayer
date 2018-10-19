//
//  yas_path_utils.cpp
//

#include "yas_url.h"

using namespace yas;

struct url::impl : base::impl {
    std::string _str;

    impl(std::string const &str) : _str(str) {
        if (this->_str.back() == '/') {
            this->_str.pop_back();
        }
    }
};

url::url(std::string const &str) : base(std::make_shared<impl>(str)) {
}

std::string url::path() const {
    return impl_ptr<impl>()->_str;
}

url url::appending(std::string const &str) {
    return impl_ptr<impl>()->_str + "/" + str;
}
