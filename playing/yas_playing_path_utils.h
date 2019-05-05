//
//  yas_playing_url.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_file_path.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_time.h>

namespace yas::playing::path_utils {
[[nodiscard]] std::string channel_name(int64_t const ch_idx);
[[nodiscard]] std::string fragment_name(int64_t const frg_idx);
[[nodiscard]] std::string sample_type_name(std::type_info const &);
[[nodiscard]] std::string signal_file_name(proc::time::range const &, std::type_info const &);

[[nodiscard]] std::string channel_path(std::string const &root_path, int64_t const ch_idx);
[[nodiscard]] std::string fragment_path(std::string const &root_path, int64_t const ch_idx, int64_t const frg_idx);
[[nodiscard]] std::string signal_file_path(std::string const &root_path, int64_t const ch_idx, int64_t const frg_idx,
                                           proc::time::range const &, std::type_info const &);
[[nodiscard]] std::string number_file_path(std::string const &root_path, int64_t const ch_idx, int64_t const frg_idx);
}  // namespace yas::playing::path_utils
