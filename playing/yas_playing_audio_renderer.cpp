//
//  yas_playing_audio_renderer.cpp
//

#include "yas_playing_audio_renderer.h"
#include <audio/yas_audio_engine_au.h>
#include <audio/yas_audio_engine_au_io.h>
#include <audio/yas_audio_engine_tap.h>
#include <audio/yas_audio_format.h>

using namespace yas;
using namespace yas::playing;

struct audio_renderer::impl : base::impl, audio_renderable::impl {
    audio::engine::manager _manager;
    chaining::value::holder<proc::sample_rate_t> _sample_rate{proc::sample_rate_t{0}};
    chaining::value::holder<audio::pcm_format> _pcm_format{audio::pcm_format::float32};
    chaining::value::holder<std::size_t> _channel_count{std::size_t(0)};
    chaining::value::holder<audio_configuration> _configuration{
        {.sample_rate = 0, .pcm_format = audio::pcm_format::float32, .channel_count = 0}};

    void prepare(audio_renderer &renderer) {
        auto weak_renderer = to_weak(renderer);

        this->_setup_tap(weak_renderer);

        this->_pool += this->_sample_rate.chain()
                           .to_null()
                           .merge(this->_pcm_format.chain().to_null())
                           .merge(this->_channel_count.chain().to_null())
                           .perform([weak_renderer](auto const &) {
                               if (auto renderer = weak_renderer.lock()) {
                                   auto renderer_impl = renderer.impl_ptr<impl>();
                                   renderer_impl->_configuration.set_value(
                                       audio_configuration{.sample_rate = renderer_impl->_sample_rate.raw(),
                                                           .pcm_format = renderer_impl->_pcm_format.raw(),
                                                           .channel_count = renderer_impl->_channel_count.raw()});
                               }
                           })
                           .sync();

        this->_update_configuration();

        this->_pool += this->_manager.chain(audio::engine::manager::method::configuration_change)
                           .perform([weak_renderer](audio::engine::manager const &) {
                               if (auto renderer = weak_renderer.lock()) {
                                   renderer.impl_ptr<impl>()->_update_configuration();
                               }
                           })
                           .end();

        this->_pool += this->_configuration.chain()
                           .perform([weak_renderer](auto const &) {
                               if (auto renderer = weak_renderer.lock()) {
                                   renderer.impl_ptr<impl>()->_update_connection();
                               }
                           })
                           .sync();

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
    }

    void set_rendering_handler(audio_renderable::rendering_f &&handler) override {
        std::lock_guard<std::recursive_mutex> lock(this->_rendering_mutex);
        this->_rendering_handler = handler;
    }

    chaining::chain_sync_t<proc::sample_rate_t> chain_sample_rate() override {
        return this->_sample_rate.chain();
    }

    chaining::chain_sync_t<audio::pcm_format> chain_pcm_format() override {
        return this->_pcm_format.chain();
    }

    chaining::chain_sync_t<std::size_t> chain_channel_count() override {
        return this->_channel_count.chain();
    }

    void set_is_rendering(bool const is_rendering) override {
        this->_is_rendering.set_value(is_rendering);
    }

   private:
    audio::engine::au_output _output;
    audio::engine::tap _tap;
    audio::engine::connection _connection = nullptr;

    chaining::observer_pool _pool;

    chaining::value::holder<bool> _is_rendering{false};
    audio_renderable::rendering_f _rendering_handler;
    std::recursive_mutex _rendering_mutex;

    void _setup_tap(weak<audio_renderer> weak_renderer) {
        this->_tap.set_render_handler(
            [weak_renderer = std::move(weak_renderer)](audio::engine::node::render_args args) {
                if (args.bus_idx != 0) {
                    return;
                }

                if (auto renderer = weak_renderer.lock()) {
                    renderer.impl_ptr<impl>()->_render(args.buffer);
                }
            });
    }

    void _update_configuration() {
        audio::engine::au_io const &au_io = this->_output.au_io();
        proc::sample_rate_t const sample_rate =
            static_cast<proc::sample_rate_t>(std::round(au_io.device_sample_rate()));
        uint32_t const ch_count = au_io.output_device_channel_count();
        this->_sample_rate.set_value(sample_rate);
        this->_channel_count.set_value(ch_count);
    }

    void _update_connection() {
        if (this->_connection) {
            this->_manager.disconnect(this->_connection);
            this->_connection = nullptr;
        }

        double const &sample_rate = this->_sample_rate.raw();
        std::size_t const ch_count = this->_channel_count.raw();

        if (sample_rate > 0.0 && ch_count > 0) {
            audio::format format{{.sample_rate = sample_rate, .channel_count = static_cast<uint32_t>(ch_count)}};
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

audio::engine::manager const &audio_renderer::manager() {
    return impl_ptr<impl>()->_manager;
}

proc::sample_rate_t audio_renderer::sample_rate() const {
    return impl_ptr<impl>()->_sample_rate.raw();
}

audio::pcm_format audio_renderer::pcm_format() const {
    return impl_ptr<impl>()->_pcm_format.raw();
}

std::size_t audio_renderer::channel_count() const {
    return impl_ptr<impl>()->_channel_count.raw();
}

chaining::chain_sync_t<audio_configuration> audio_renderer::configuration_chain() const {
    return impl_ptr<impl>()->_configuration.chain();
}

audio_renderable &audio_renderer::renderable() {
    if (!this->_renderable) {
        this->_renderable = audio_renderable{impl_ptr<impl>()};
    }
    return this->_renderable;
}
