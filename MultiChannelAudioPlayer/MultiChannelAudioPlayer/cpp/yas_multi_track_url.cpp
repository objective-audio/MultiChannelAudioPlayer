//
//  yas_multi_track_url.cpp
//

#include "yas_multi_track_url.h"
#include "yas_math.h"

using namespace yas;

yas::url multi_track::track_url(yas::url const &root_url, uint32_t const trk_idx) {
    return root_url.appending(std::to_string(trk_idx));
}

yas::url multi_track::file_url(yas::url const &trk_url, int64_t const file_frame_idx, int64_t const sample_rate) {
    int64_t const floored_frame_idx = math::floor_int(file_frame_idx, sample_rate);
    return trk_url.appending(std::to_string(floored_frame_idx / (int64_t)sample_rate) + ".caf");
}
