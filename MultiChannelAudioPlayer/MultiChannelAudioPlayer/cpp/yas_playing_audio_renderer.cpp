//
//  yas_playing_audio_renderer.cpp
//

#include "yas_playing_audio_renderer.h"

using namespace yas;
using namespace yas::playing;

struct audio_renderer::impl : base::impl, audio_renderable::impl {
    chaining::holder<double> _sample_rate{0.0};
    chaining::holder<audio::pcm_format> _pcm_format{audio::pcm_format::float32};
    chaining::holder<uint32_t> _channel_count{uint32_t(0)};
    bool _is_rendering = false;
    audio_renderable::rendering_f _rendering_handler;

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
        this->_is_rendering = is_rendering;
    }
};

audio_renderer::audio_renderer() : base(std::make_shared<impl>()) {
}

audio_renderer::audio_renderer(std::nullptr_t) : base(nullptr) {
}

audio_renderable &audio_renderer::renderable() {
    if (!this->_renderable) {
        this->_renderable = audio_renderable{impl_ptr<impl>()};
    }
    return this->_renderable;
}
