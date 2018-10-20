//
//  yas_math.cpp
//

#include "yas_math.h"

using namespace yas;

int64_t math::floor_int(int64_t const value, uint64_t const range) {
    if (value == 0) {
        return 0;
    } else if (value > 0) {
        return value - value % (int64_t)range;
    } else {
        return value - ((int64_t)range + value % (int64_t)range);
    }

}
