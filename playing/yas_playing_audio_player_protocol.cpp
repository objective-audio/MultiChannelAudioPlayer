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

chaining::chain_sync_t<proc::sample_rate_t> audio_renderable::chain_sample_rate() {
    return impl_ptr<impl>()->chain_sample_rate();
}

chaining::chain_sync_t<audio::pcm_format> audio_renderable::chain_pcm_format() {
    return impl_ptr<impl>()->chain_pcm_format();
}

chaining::chain_sync_t<std::size_t> audio_renderable::chain_channel_count() {
    return impl_ptr<impl>()->chain_channel_count();
}

void audio_renderable::set_is_rendering(bool const is_rendering) {
    impl_ptr<impl>()->set_is_rendering(is_rendering);
}
