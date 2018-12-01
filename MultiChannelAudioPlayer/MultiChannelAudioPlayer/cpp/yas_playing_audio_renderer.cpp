//
//  yas_playing_audio_renderer.cpp
//

#include "yas_playing_audio_renderer.h"
#include "yas_audio_engine_au.h"
#include "yas_audio_engine_au_io.h"
#include "yas_audio_engine_manager.h"
#include "yas_audio_engine_tap.h"
#include "yas_audio_format.h"

using namespace yas;
using namespace yas::playing;

struct audio_renderer::impl : base::impl, audio_renderable::impl {
    void prepare(audio_renderer &renderer) {
        auto weak_renderer = to_weak(renderer);

        this->_pool +=
            this->_manager.chain(audio::engine::manager::method::configuration_change)
                .perform([](audio::engine::manager const &manager) { manager.impl_ptr<impl>()->_update_connection(); })
                .end();

        this->_pool += this->_is_rendering.chain()
                           .perform([weak_renderer](bool const &is_rendering) {
                               if (auto renderer = weak_renderer.lock()) {
                                   if (is_rendering) {
                                       renderer.impl_ptr<impl>()->_manager.start_render();
                                   } else {
                                       renderer.impl_ptr<impl>()->_manager.stop();
                                   }
                               }
                           })
                           .sync();

        this->_update_connection();
    }

    void set_rendering_handler(audio_renderable::rendering_f &&handler) override {
        this->_rendering_handler = handler;
    }

    chaining::chain_sync_t<double> chain_sample_rate() override {
        return this->_sample_rate.chain();
    }

    chaining::chain_sync_t<audio::pcm_format> chain_pcm_format() override {
        return this->_pcm_format.chain();
    }

    chaining::chain_sync_t<uint32_t> chain_channel_count() override {
        return this->_channel_count.chain();
    }

    void set_is_rendering(bool const is_rendering) override {
        this->_is_rendering.set_value(is_rendering);
    }

   private:
    audio::engine::manager _manager;
    audio::engine::au_output _output;
    audio::engine::tap _tap;
    audio::engine::connection _connection = nullptr;

    chaining::observer_pool _pool;

    chaining::holder<double> _sample_rate{0.0};
    chaining::holder<audio::pcm_format> _pcm_format{audio::pcm_format::float32};
    chaining::holder<uint32_t> _channel_count{uint32_t(0)};
    chaining::holder<bool> _is_rendering{false};
    audio_renderable::rendering_f _rendering_handler;
    std::recursive_mutex _rendering_mutex;

    void _update_connection() {
        if (this->_connection) {
            this->_manager.disconnect(this->_connection);
            this->_connection = nullptr;
        }

        audio::engine::au_io const &au_io = this->_output.au_io();
        double const sample_rate = au_io.device_sample_rate();
        uint32_t const ch_count = au_io.output_device_channel_count();
        this->_sample_rate.set_value(sample_rate);
        this->_channel_count.set_value(ch_count);

        if (sample_rate > 0.0 && ch_count > 0) {
            audio::format format{{.sample_rate = sample_rate, .channel_count = ch_count}};
            this->_connection = this->_manager.connect(this->_tap.node(), this->_output.au_io().au().node(), format);
        }
    }

    void _render(audio::pcm_buffer &buffer) {
        auto const &format = buffer.format();

        if (format.is_interleaved()) {
            throw std::invalid_argument("buffer is not non-interleaved.");
        }

        if (auto lock = std::unique_lock<std::recursive_mutex>(this->_rendering_mutex, std::try_to_lock);
            lock.owns_lock()) {
            if (auto const &handler = this->_rendering_handler) {
                handler(buffer);
            }
        }
    }
};

audio_renderer::audio_renderer() : base(std::make_shared<impl>()) {
    impl_ptr<impl>()->prepare(*this);
}

audio_renderer::audio_renderer(std::nullptr_t) : base(nullptr) {
}

audio_renderable &audio_renderer::renderable() {
    if (!this->_renderable) {
        this->_renderable = audio_renderable{impl_ptr<impl>()};
    }
    return this->_renderable;
}
