//
//  yas_playing_audio_player.h
//

#pragma once

#include "yas_audio.h"
#include "yas_base.h"
#include "yas_url.h"

namespace yas::playing {
struct audio_player : base {
    class impl;

    audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                 uint32_t const ch_count);

    void play();
    void stop();
    void seek(int64_t const frame_idx);
    void reload(int64_t const ch_idx, int64_t const file_idx);
};
}  // namespace yas::playing
