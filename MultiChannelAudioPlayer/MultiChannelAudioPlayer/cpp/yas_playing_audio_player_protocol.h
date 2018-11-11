//
//  yas_playing_audio_player_protocol.h
//

#pragma once

#include <functional>
#include "yas_audio_pcm_buffer.h"
#include "yas_protocol.h"

namespace yas::playing {
struct audio_renderable : protocol {
    using rendering_f = std::function<void(audio::pcm_buffer &)>;

    struct impl : protocol::impl {
        virtual void set_rendering_handler(rendering_f &&) = 0;
    };

    explicit audio_renderable(std::shared_ptr<impl> impl);
    audio_renderable(std::nullptr_t);

    void set_rendering_handler(rendering_f);
};
}  // namespace yas::playing
