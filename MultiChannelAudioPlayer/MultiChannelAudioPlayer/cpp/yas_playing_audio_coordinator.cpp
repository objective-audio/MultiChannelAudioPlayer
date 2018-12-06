//
//  yas_playing_audio_coordinator.cpp
//

#include "yas_playing_audio_coordinator.h"
#include "yas_chaining.h"
#include "yas_playing_audio_exporter.h"
#include "yas_playing_audio_player.h"
#include "yas_playing_audio_renderer.h"
#include "yas_url.h"

using namespace yas;
using namespace yas::playing;

struct audio_coordinator::impl : base::impl {
    url _root_url;
    operation_queue _queue;
    audio_renderer _renderer;
    audio_player _player{this->_renderer.renderable(), this->_root_url, this->_queue};
    audio_exporter _exporter = nullptr;

    chaining::observer_pool _pool;

    impl(url &&root_url) : _root_url(std::move(root_url)) {
    }

    void prepare(audio_coordinator &coordinator) {
        auto weak_coordinator = to_weak(coordinator);

        this->_pool += this->_renderer.manager()
                           .chain(audio::engine::manager::method::configuration_change)
                           .perform([weak_coordinator](auto const &manager) {
                               if (auto coordinator = weak_coordinator.lock()) {
                                   coordinator.impl_ptr<impl>()->update_exporter(manager);
                               }
                           })
                           .end();
    }

   private:
    void update_exporter(audio::engine::manager const &manager) {
        double const sample_rate = this->_renderer.sample_rate();
        audio::pcm_format const pcm_format = this->_renderer.pcm_format();

        if (this->_exporter) {
            if (this->_exporter.sample_rate() == sample_rate && this->_exporter.pcm_format() == pcm_format) {
                return;
            }

            this->_exporter.update_format(sample_rate, pcm_format, [] {});
        } else {
            this->_exporter = audio_exporter{sample_rate, pcm_format, this->_root_url, this->_queue};
        }
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
