//
//  yas_playing_audio_renderer.h
//

#pragma once

#include "yas_audio_engine_manager.h"
#include "yas_base.h"
#include "yas_playing_audio_player_protocol.h"

namespace yas::playing {
struct audio_renderer : base {
    class impl;

    audio_renderer();
    audio_renderer(std::nullptr_t);

    audio::engine::manager const &manager();

    audio_renderable &renderable();

   private:
    audio_renderable _renderable = nullptr;
};
}  // namespace yas::playing