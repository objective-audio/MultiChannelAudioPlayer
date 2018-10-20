//
//  yas_math.cpp
//

#include "yas_math.h"
#include <iostream>

using namespace yas;

int64_t math::floor_int(int64_t const value, uint32_t const range) {
    if (value == 0) {
        return 0;
    } else if (int64_t const mod = value % range; value > 0) {
        return value - mod;
    } else if (mod != 0) {
        return value - (mod + range);
    } else {
        return value;
    }
}
