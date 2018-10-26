//
//  yas_multi_track_audio_player.h
//

#pragma once

#include "yas_audio.h"
#include "yas_base.h"
#include "yas_url.h"

namespace yas::multi_track {
struct audio_player : base {
    class impl;

    audio_player(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url);

    void play();
    void stop();
    void seek(int64_t const frame_idx);
};
}  // namespace yas::multi_track
