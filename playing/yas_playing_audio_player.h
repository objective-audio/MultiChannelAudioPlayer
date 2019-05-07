//
//  yas_playing_audio_player.h
//

#pragma once

#include <cpp_utils/yas_base.h>
#include <cpp_utils/yas_task.h>
#include "yas_playing_audio_player_protocol.h"

namespace yas::playing {
struct audio_player : base {
    class impl;

    audio_player(audio_renderable renderable, std::string const &root_path, task_queue queue);
    audio_player(std::nullptr_t);

    void set_ch_mapping(std::vector<int64_t>);
    void set_playing(bool const);
    void seek(int64_t const play_frame);
    void reload(int64_t const ch_idx, int64_t const frag_idx);
    void reload_all();

    [[nodiscard]] std::string const &root_path() const;
    [[nodiscard]] std::vector<int64_t> const &ch_mapping() const;
    [[nodiscard]] bool is_playing() const;
    [[nodiscard]] int64_t play_frame() const;
};
}  // namespace yas::playing
