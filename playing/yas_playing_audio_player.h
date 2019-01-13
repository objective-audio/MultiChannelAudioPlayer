//
//  yas_playing_audio_player.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_operation.h>
#include <cpp_utils/yas_url.h>
#include "yas_playing_audio_player_protocol.h"

namespace yas::playing {
struct audio_player : base {
    class impl;

    audio_player(audio_renderable renderable, url const &root_url, operation_queue queue);
    audio_player(std::nullptr_t);

    void set_ch_mapping(std::vector<int64_t>);
    void set_playing(bool const);
    void seek(int64_t const play_frame);
    void reload(int64_t const ch_idx, int64_t const file_idx);

    [[nodiscard]] url root_url() const;
    [[nodiscard]] std::vector<int64_t> const &ch_mapping() const;
    [[nodiscard]] bool is_playing() const;
    [[nodiscard]] int64_t play_frame() const;
};
}  // namespace yas::playing
