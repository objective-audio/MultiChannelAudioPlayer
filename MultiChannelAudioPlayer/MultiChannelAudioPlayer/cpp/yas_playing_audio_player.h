//
//  yas_playing_audio_player.h
//

#pragma once

#include "yas_audio.h"
#include "yas_base.h"
#include "yas_playing_audio_player_protocol.h"
#include "yas_url.h"

namespace yas::playing {
struct audio_player : base {
    class impl;

    audio_player(audio_renderable renderable, url const &root_url);
    audio_player(std::nullptr_t);

    void set_playing(bool const);
    void seek(int64_t const play_frame);
    void reload(int64_t const ch_idx, int64_t const file_idx);

    bool is_playing() const;
    int64_t play_frame() const;
};
}  // namespace yas::playing
