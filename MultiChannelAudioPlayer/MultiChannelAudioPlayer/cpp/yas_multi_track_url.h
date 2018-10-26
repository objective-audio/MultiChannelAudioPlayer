//
//  yas_multi_track_url.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::multi_track {
struct url : base {
    class impl;

    url(yas::url const &root_url);

    yas::url track_url(uint32_t const trk_idx);
    yas::url file_url(uint32_t const trk_idx, int64_t const file_idx);
};
}  // namespace yas::multi_track
