//
//  yas_playing_audio_player_protocol.h
//

#pragma once

#include <functional>
#include "yas_protocol.h"

namespace yas::playing {
struct audio_renderable : protocol {
    struct impl : protocol::impl {
        virtual void set_rendering_handler(std::function<void(void)> &&);
    };

    explicit audio_renderable(std::shared_ptr<impl> impl);
    audio_renderable(std::nullptr_t);

    void set_rendering_handler(std::function<void(void)>);
};
}  // namespace yas::playing
