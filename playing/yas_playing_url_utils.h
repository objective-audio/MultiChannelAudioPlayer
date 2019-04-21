//
//  yas_playing_url.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_url.h>

namespace yas::playing::url_utils {
[[nodiscard]] yas::url channel_url(yas::url const &root_url, int64_t const ch_idx);
[[nodiscard]] yas::url fragment_url(yas::url const &root_url, int64_t const ch_idx, int64_t const frg_idx);
[[nodiscard]] yas::url caf_url(yas::url const &ch_url, int64_t const file_idx);
[[nodiscard]] int64_t caf_idx(int64_t const file_frame_idx, uint64_t const file_length);
}  // namespace yas::playing::url_utils
