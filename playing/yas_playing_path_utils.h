//
//  yas_playing_url.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_file_path.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_types.h"

namespace yas::playing::path_utils {
[[nodiscard]] std::string channel_name(channel_index_t const ch_idx);
[[nodiscard]] std::string fragment_name(fragment_index_t const frag_idx);

[[nodiscard]] std::string channel_path(std::string const &root_path, channel_index_t const ch_idx);
[[nodiscard]] std::string fragment_path(std::string const &channel_path, fragment_index_t const frag_idx);
[[nodiscard]] std::string signal_file_path(std::string const &fragment_path, proc::time::range const &,
                                           std::type_info const &);
[[nodiscard]] std::string number_file_path(std::string const &fragment_path);

[[nodiscard]] std::string fragment_path(std::string const &root_path, channel_index_t const ch_idx,
                                        fragment_index_t const frag_idx);
[[nodiscard]] std::string signal_file_path(std::string const &root_path, channel_index_t const ch_idx,
                                           fragment_index_t const frag_idx, proc::time::range const &,
                                           std::type_info const &);

[[nodiscard]] std::string number_file_path(std::string const &root_path, channel_index_t const ch_idx,
                                           fragment_index_t const frag_idx);
}  // namespace yas::playing::path_utils
