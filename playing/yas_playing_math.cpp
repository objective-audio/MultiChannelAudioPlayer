//
//  yas_playing_math.cpp
//

#include "yas_playing_math.h"

using namespace yas;
using namespace yas::playing;

int64_t math::floor_int(int64_t const value, uint64_t const interval) {
    if (interval == 0) {
        return value;
    } else if (value == 0) {
        return 0;
    } else if (int64_t const mod = value % static_cast<int64_t>(interval); mod == 0) {
        return value;
    } else if (value > 0) {
        return value - mod;
    } else {
        return value - mod - static_cast<int64_t>(interval);
    }
}

int64_t ceil_int(int64_t const value, uint64_t const interval) {
    if (interval == 0) {
        return value;
    } else if (value == 0) {
        return 0;
    } else if (int64_t const mod = value % static_cast<int64_t>(interval); mod == 0) {
        return value;
    } else if (value > 0) {
        return value - mod + interval;
    } else {
        return value - mod;
    }
}
