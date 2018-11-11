//
//  yas_playing_audio_player_protocol.cpp
//

#include "yas_playing_audio_player_protocol.h"

using namespace yas;
using namespace yas::playing;

audio_renderable::audio_renderable(std::shared_ptr<impl> impl) : protocol(std::move(impl)) {
}

audio_renderable::audio_renderable(std::nullptr_t) : protocol(nullptr) {
}

void audio_renderable::set_rendering_handler(audio_renderable::rendering_f handler) {
    impl_ptr<impl>()->set_rendering_handler(std::move(handler));
}
