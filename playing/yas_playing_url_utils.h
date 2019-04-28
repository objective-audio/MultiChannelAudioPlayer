//
//  yas_playing_url.h
//

#pragma once

#include <audio/yas_audio_types.h>
#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_time.h>

namespace yas::playing::url_utils {
[[nodiscard]] std::string channel_name(int64_t const ch_idx);
[[nodiscard]] std::string fragment_name(int64_t const frag_idx);
[[nodiscard]] std::string signal_file_name(proc::time::range const &);

[[nodiscard]] yas::url channel_url(yas::url const &root_url, int64_t const ch_idx);
[[nodiscard]] yas::url fragment_url(yas::url const &root_url, int64_t const ch_idx, int64_t const frg_idx);
[[nodiscard]] yas::url caf_url(yas::url const &ch_url, int64_t const file_idx);
[[nodiscard]] int64_t caf_idx(int64_t const file_frame_idx, uint64_t const file_length);
}  // namespace yas::playing::url_utils
