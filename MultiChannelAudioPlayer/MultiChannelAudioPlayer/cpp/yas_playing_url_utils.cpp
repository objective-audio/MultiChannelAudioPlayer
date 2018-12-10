//
//  yas_playing_url.cpp
//

#include "yas_playing_url_utils.h"
#include "yas_math.h"

using namespace yas::playing;

yas::url url_utils::channel_url(yas::url const &root_url, int64_t const ch_idx) {
    return root_url.appending(std::to_string(ch_idx));
}

yas::url url_utils::caf_url(yas::url const &ch_url, int64_t const file_idx) {
    return ch_url.appending(std::to_string(file_idx) + ".caf");
}

int64_t url_utils::caf_idx(int64_t const file_frame_idx, uint64_t const file_length) {
    int64_t const floored_frame_idx = math::floor_int(file_frame_idx, file_length);
    return floored_frame_idx / (int64_t)file_length;
}
