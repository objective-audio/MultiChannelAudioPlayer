//
//  yas_math.cpp
//

#include "yas_math.h"
#include <iostream>

using namespace yas;

int64_t math::floor_int(int64_t const value, uint64_t const range) {
    if (value == 0) {
        return 0;
    } else if (value > 0) {
        return value - value % (int64_t)range;
    } else {
        std::cout << "value[" + std::to_string(value) + "] - (range[" + std::to_string(range) + "] + [" +
                         std::to_string(value % (int64_t)range) + "]"
                  << std::endl;
        return value - ((int64_t)range + value % (int64_t)range);
    }
}
