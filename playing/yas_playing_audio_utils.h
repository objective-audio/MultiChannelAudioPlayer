//
//  yas_playing_audio_utils.h
//

#pragma once

#include <cstdint>
#include <optional>
#include "yas_playing_types.h"

namespace yas::playing::audio_utils {
struct processing_info {
    uint32_t const length;
    std::optional<fragment_index_t> const next_frag_idx;

    processing_info(frame_index_t const play_frame, frame_index_t const next_frame, uint32_t const file_length);
};
}  // namespace yas::playing::audio_utils
