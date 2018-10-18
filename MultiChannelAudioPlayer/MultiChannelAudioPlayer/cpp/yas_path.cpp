//
//  yas_path_utils.cpp
//

#include "yas_path.h"

using namespace yas;

path::path(std::string const &str) : _str(str) {
    if (this->_str.back() == '/') {
        this->_str.pop_back();
    }
}

std::string path::str() const {
    return this->_str;
}

path path::append(std::string const &str) {
    return this->_str + "/" + str;
}
