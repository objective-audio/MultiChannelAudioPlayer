//
//  yas_playing_url.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_file_path.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_types.h"

namespace yas::playing {
struct channel_path {
    std::string const root_path;
    channel_index_t const channel_index;

    std::string string() const;
};

struct fragment_path {
    channel_path const channel_path;
    fragment_index_t const fragment_index;

    std::string string() const;
};

struct signal_event_path {
    fragment_path const fragment_path;
    proc::time::range const range;
    std::type_info const &sample_type;

    std::string string() const;
};

struct number_events_path {
    fragment_path const fragment_path;

    std::string string() const;
};

[[nodiscard]] channel_path make_channel_path(std::string const &root_path, channel_index_t const);
[[nodiscard]] fragment_path make_fragment_path(channel_path const &, fragment_index_t const);
[[nodiscard]] signal_event_path make_signal_event_path(fragment_path const &, proc::time::range const &,
                                                       std::type_info const &);
[[nodiscard]] number_events_path make_number_events_path(fragment_path const &);
}  // namespace yas::playing

namespace yas::playing::path_utils {
[[nodiscard]] std::string channel_name(channel_index_t const ch_idx);
[[nodiscard]] std::string fragment_name(fragment_index_t const frag_idx);

[[nodiscard]] std::string signal_file_path(std::string const &root_path, channel_index_t const ch_idx,
                                           fragment_index_t const frag_idx, proc::time::range const &,
                                           std::type_info const &);
}  // namespace yas::playing::path_utils
