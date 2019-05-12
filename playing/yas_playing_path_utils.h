//
//  yas_playing_url.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_file_path.h>
#include <cpp_utils/yas_url.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_types.h"

namespace yas::playing::path {
struct [[nodiscard]] timeline {
    std::string const root_path;
    std::string const identifier;
    proc::sample_rate_t const sample_rate;

    timeline(std::string const &root_path, std::string const identifier, proc::sample_rate_t const);

    [[nodiscard]] std::string string() const;
};

struct [[nodiscard]] channel {
    timeline const timeline_path;
    channel_index_t const channel_index;

    channel(timeline const &, channel_index_t const);

    [[nodiscard]] std::string string() const;
};

struct [[nodiscard]] fragment {
    channel const channel_path;
    fragment_index_t const fragment_index;

    fragment(path::channel const &, fragment_index_t const);

    [[nodiscard]] std::string string() const;
};

struct [[nodiscard]] signal_event {
    fragment const fragment_path;
    proc::time::range const range;
    std::type_info const &sample_type;

    signal_event(path::fragment const &, proc::time::range const &, std::type_info const &);

    [[nodiscard]] std::string string() const;
};

struct [[nodiscard]] number_events {
    fragment const fragment_path;

    number_events(path::fragment const &);

    [[nodiscard]] std::string string() const;
};

[[nodiscard]] std::string timeline_name(std::string const &identifier, sample_rate_t const);
[[nodiscard]] std::string channel_name(channel_index_t const ch_idx);
[[nodiscard]] std::string fragment_name(fragment_index_t const frag_idx);
}  // namespace yas::playing::path
