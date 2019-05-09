//
//  yas_playing_audio_utils.cpp
//

#include "yas_playing_audio_utils.h"
#include <algorithm>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::audio_utils {
static uint32_t processing_length(frame_index_t const play_frame, frame_index_t const next_frame,
                                  uint32_t const file_length) {
    return std::min(uint32_t(next_frame - play_frame), uint32_t(file_length - (play_frame % file_length)));
}

static std::optional<int64_t> get_next_file_idx(frame_index_t const play_frame, uint32_t const proc_length,
                                                uint32_t const file_length) {
    frame_index_t const next_frame = play_frame + proc_length;
    if (next_frame % file_length == 0) {
        return next_frame / file_length;
    } else {
        return std::nullopt;
    }
}
}  // namespace yas::playing::audio_utils

audio_utils::processing_info::processing_info(frame_index_t const play_frame, frame_index_t const next_frame,
                                              uint32_t const file_length)
    : length(processing_length(play_frame, next_frame, file_length)),
      next_frag_idx(get_next_file_idx(play_frame, this->length, file_length)) {
}
