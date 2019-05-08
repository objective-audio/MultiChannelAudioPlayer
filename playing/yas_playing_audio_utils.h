//
//  yas_playing_audio_utils.h
//

#pragma once

#include <cstdint>
#include <optional>

namespace yas::playing::audio_utils {
struct processing_info {
    uint32_t const length;
    std::optional<int64_t> const next_frag_idx;

    processing_info(int64_t const play_frame, int64_t const next_frame, uint32_t const file_length);
};
}  // namespace yas::playing::audio_utils
