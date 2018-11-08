//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include "yas_audio_pcm_buffer.h"
#include "yas_operation.h"
#include "yas_url.h"

namespace yas::playing {
struct audio_circular_buffer : base {
    class impl;

    audio_circular_buffer(audio::format const &format, std::size_t const container_count, url const &ch_url,
                          operation_queue queue);
    explicit audio_circular_buffer(std::nullptr_t);

    void read_into_buffer(audio::pcm_buffer &out_buffer, int64_t const play_frame);
    void seek(int64_t const frame);
};
}  // namespace yas::playing
