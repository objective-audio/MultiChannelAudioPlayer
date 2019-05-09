//
//  yas_playing_audio_player_protocol.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_protocol.h>
#include <processing/yas_processing_types.h>
#include <functional>

namespace yas::playing {
struct audio_renderable : protocol {
    using rendering_f = std::function<void(audio::pcm_buffer &)>;

    struct impl : protocol::impl {
        virtual void set_rendering_handler(rendering_f &&) = 0;
        virtual chaining::chain_sync_t<proc::sample_rate_t> chain_sample_rate() = 0;
        virtual chaining::chain_sync_t<audio::pcm_format> chain_pcm_format() = 0;
        virtual chaining::chain_sync_t<std::size_t> chain_channel_count() = 0;
        virtual void set_is_rendering(bool const) = 0;
    };

    explicit audio_renderable(std::shared_ptr<impl> impl);
    audio_renderable(std::nullptr_t);

    void set_rendering_handler(rendering_f);
    chaining::chain_sync_t<proc::sample_rate_t> chain_sample_rate();
    chaining::chain_sync_t<audio::pcm_format> chain_pcm_format();
    chaining::chain_sync_t<std::size_t> chain_channel_count();
    void set_is_rendering(bool const);
};
}  // namespace yas::playing
