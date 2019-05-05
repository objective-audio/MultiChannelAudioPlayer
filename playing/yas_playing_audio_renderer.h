//
//  yas_playing_audio_renderer.h
//

#pragma once

#include <audio/yas_audio_engine_manager.h>
#include <cpp_utils/yas_base.h>
#include "yas_playing_audio_player_protocol.h"
#include "yas_playing_types.h"

namespace yas::playing {
struct audio_renderer : base {
    class impl;

    audio_renderer();
    audio_renderer(std::nullptr_t);

    [[nodiscard]] audio::engine::manager const &manager();
    [[nodiscard]] double sample_rate() const;
    [[nodiscard]] audio::pcm_format pcm_format() const;
    [[nodiscard]] uint32_t channel_count() const;

    [[nodiscard]] chaining::chain_sync_t<audio_configuration> configuration_chain() const;

    [[nodiscard]] audio_renderable &renderable();

   private:
    audio_renderable _renderable = nullptr;
};
}  // namespace yas::playing
