//
//  yas_playing_audio_coordinator.cpp
//

#include "yas_playing_audio_coordinator.h"
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_url.h>
#include "yas_playing_audio_player.h"
#include "yas_playing_audio_renderer.h"
#include "yas_playing_types.h"

using namespace yas;
using namespace yas::playing;

struct audio_coordinator::impl : base::impl {
    url _root_url;
    task_queue _queue{queue_priority_count};
    audio_renderer _renderer;
    audio_player _player{this->_renderer.renderable(), this->_root_url, this->_queue};

    chaining::observer_pool _pool;

    impl(url &&root_url) : _root_url(std::move(root_url)) {
    }

    void prepare(audio_coordinator &coordinator) {
        auto weak_coordinator = to_weak(coordinator);

        this->_pool += this->_renderer.chain_configuration()
                           .perform([weak_coordinator](auto const &configuration) {
                               if (auto coordinator = weak_coordinator.lock()) {
#warning todo configurationが変わったのでリロードする
                               }
                           })
                           .sync();
    }
};

audio_coordinator::audio_coordinator(url root_url) : base(std::make_shared<impl>(std::move(root_url))) {
    impl_ptr<impl>()->prepare(*this);
}

audio_coordinator::audio_coordinator(std::nullptr_t) : base(nullptr) {
}

void audio_coordinator::set_playing(bool const is_playing) {
    impl_ptr<impl>()->_player.set_playing(is_playing);
}

void audio_coordinator::seek(int64_t const play_frame) {
    impl_ptr<impl>()->_player.seek(play_frame);
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
    return impl_ptr<impl>()->_renderer.chain_configuration();
}
