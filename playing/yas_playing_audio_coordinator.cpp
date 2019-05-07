//
//  yas_playing_audio_coordinator.cpp
//

#include "yas_playing_audio_coordinator.h"
#include <chaining/yas_chaining_umbrella.h>
#include "yas_playing_audio_player.h"
#include "yas_playing_audio_renderer.h"
#include "yas_playing_types.h"

using namespace yas;
using namespace yas::playing;

struct audio_coordinator::impl : base::impl {
    std::string _root_path;
    task_queue _queue{queue_priority_count};
    audio_renderer _renderer;
    audio_player _player{this->_renderer.renderable(), this->_root_path, this->_queue};

    chaining::observer_pool _pool;

    impl(std::string &&root_path) : _root_path(std::move(root_path)) {
    }
};

audio_coordinator::audio_coordinator(std::string root_path) : base(std::make_shared<impl>(std::move(root_path))) {
}

audio_coordinator::audio_coordinator(std::nullptr_t) : base(nullptr) {
}

void audio_coordinator::set_playing(bool const is_playing) {
    impl_ptr<impl>()->_player.set_playing(is_playing);
}

void audio_coordinator::seek(int64_t const play_frame) {
    impl_ptr<impl>()->_player.seek(play_frame);
}

void audio_coordinator::reload_all() {
#warning todo
}

void audio_coordinator::reload(proc::time::range const &range) {
#warning todo
}

double audio_coordinator::sample_rate() const {
    return impl_ptr<impl>()->_renderer.sample_rate();
}

audio::pcm_format audio_coordinator::pcm_format() const {
    return impl_ptr<impl>()->_renderer.pcm_format();
}

uint32_t audio_coordinator::channel_count() const {
    return impl_ptr<impl>()->_renderer.channel_count();
}

chaining::chain_sync_t<audio_configuration> audio_coordinator::chain_configuration() const {
    return impl_ptr<impl>()->_renderer.configuration_chain();
}
