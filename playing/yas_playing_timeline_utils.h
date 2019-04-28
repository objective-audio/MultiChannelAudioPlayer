//
//  yas_playing_timeline_utils.h
//

#pragma once

#include <audio/yas_audio_types.h>
#include <processing/yas_processing_time.h>

namespace yas::playing::timeline_utils {
[[nodiscard]] proc::time::range fragments_range(proc::time::range const &, proc::sample_rate_t const);
[[nodiscard]] audio::pcm_format to_pcm_format(std::type_info const &);
}  // namespace yas::playing::timeline_utils
