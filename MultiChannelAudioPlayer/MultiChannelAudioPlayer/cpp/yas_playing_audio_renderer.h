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
    double sample_rate() const;
    audio::pcm_format pcm_format() const;
    uint32_t channel_count() const;

    audio_renderable &renderable();

   private:
    audio_renderable _renderable = nullptr;
};
}  // namespace yas::playing
