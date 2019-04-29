//
//  yas_playing_timeline_utils.h
//

#pragma once

#include <audio/yas_audio_types.h>
#include <processing/yas_processing_number_event.h>
#include <processing/yas_processing_time.h>

namespace yas::playing::timeline_utils {
[[nodiscard]] proc::time::range fragments_range(proc::time::range const &, proc::sample_rate_t const);
[[nodiscard]] std::string to_string(proc::number_event const &);
}  // namespace yas::playing::timeline_utils
