//
//  yas_playing_timeline_utils.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <audio/yas_audio_types.h>
#include <cpp_utils/yas_result.h>
#include <processing/yas_processing_number_event.h>
#include <processing/yas_processing_signal_event.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_types.h"

namespace yas::playing::timeline_utils {
enum class read_number_error {
    open_stream_failed,
    read_frame_failed,
    read_sample_store_type_failed,
    read_value_failed,
    sample_store_type_not_found,
};
using read_number_result_t = result<std::multimap<frame_index_t, proc::number_event>, read_number_error>;

[[nodiscard]] proc::time::range fragments_range(proc::time::range const &, proc::sample_rate_t const);
[[nodiscard]] char const *char_data(proc::signal_event const &);
[[nodiscard]] char const *char_data(proc::time::frame::type const &);
[[nodiscard]] char const *char_data(sample_store_type const &);
[[nodiscard]] char const *char_data(proc::number_event const &);

[[nodiscard]] char *char_data(audio::pcm_buffer &);
[[nodiscard]] sample_store_type to_sample_store_type(std::type_info const &);
[[nodiscard]] std::type_info const &to_sample_type(sample_store_type const &);
[[nodiscard]] read_number_result_t read_number_events(std::string const &path);
}  // namespace yas::playing::timeline_utils
