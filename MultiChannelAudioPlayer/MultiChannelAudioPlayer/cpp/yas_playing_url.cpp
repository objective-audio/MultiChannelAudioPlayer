//
//  yas_playing_url.cpp
//

#include "yas_playing_url.h"
#include "yas_math.h"

using namespace yas;

yas::url playing::channel_url(yas::url const &root_url, uint32_t const ch_idx) {
    return root_url.appending(std::to_string(ch_idx));
}

yas::url playing::caf_url(yas::url const &ch_url, int64_t const file_frame_idx, int64_t const sample_rate) {
    int64_t const floored_frame_idx = math::floor_int(file_frame_idx, sample_rate);
    return ch_url.appending(std::to_string(floored_frame_idx / (int64_t)sample_rate) + ".caf");
}
