//
//  yas_multi_track_url.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::multi_track {
yas::url track_url(yas::url const &root_url, uint32_t const trk_idx);
yas::url file_url(yas::url const &trk_url, int64_t const file_frame_idx, int64_t const sample_rate);
}  // namespace yas::multi_track
