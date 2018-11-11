//
//  yas_playing_test_audio_renderer.h
//

#pragma once

#include "yas_base.h"
#include "yas_chaining.h"
#include "yas_playing_audio_player_protocol.h"

namespace yas::playing::test_utils {
struct test_audio_renderer : base {
    class impl;

    test_audio_renderer();
    test_audio_renderer(std::nullptr_t);

    audio_renderable &renderable();

   private:
    audio_renderable _renderable = nullptr;
};
}  // namespace yas::playing::test_utils