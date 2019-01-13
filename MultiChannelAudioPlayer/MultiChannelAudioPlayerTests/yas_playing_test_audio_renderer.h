//
//  yas_playing_test_audio_renderer.h
//

#pragma once

#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <playing/yas_playing_audio_player_protocol.h>

namespace yas::playing::test_utils {
struct test_audio_renderer : base {
    class impl;

    test_audio_renderer();
    test_audio_renderer(std::nullptr_t);

    void set_pcm_format(audio::pcm_format const);
    void set_channel_count(uint32_t const);
    void set_sample_rate(double const);

    void render(audio::pcm_buffer &buffer);

    audio_renderable &renderable();

   private:
    audio_renderable _renderable = nullptr;
};
}  // namespace yas::playing::test_utils
