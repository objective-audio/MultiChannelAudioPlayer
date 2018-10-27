//
//  yas_playing_url.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::playing::url_utils {
yas::url channel_url(yas::url const &root_url, uint32_t const ch_idx);
yas::url caf_url(yas::url const &ch_url, int64_t const file_idx);
yas::url caf_url(yas::url const &ch_url, int64_t const file_frame_idx, uint64_t const file_length);
}  // namespace yas::playing::url_utils
