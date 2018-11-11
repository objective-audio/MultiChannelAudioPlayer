//
//  yas_playing_test_audio_renderer.cpp
//

#include "yas_playing_test_audio_renderer.h"

using namespace yas;
using namespace yas::playing;
using namespace yas::playing::test_utils;

struct test_audio_renderer::impl : base::impl, audio_renderable::impl {
    chaining::holder<double> _sample_rate{0.0};
    audio_renderable::rendering_f _rendering_handler;

    void set_rendering_handler(audio_renderable::rendering_f &&handler) override {
        this->_rendering_handler = std::move(handler);
    }

    chaining::chain_sync_t<double> chain_sample_rate() override {
        return this->_sample_rate.chain();
    }
};

test_audio_renderer::test_audio_renderer() : base(std::make_shared<impl>()) {
}

test_audio_renderer::test_audio_renderer(std::nullptr_t) : base(nullptr) {
}

void test_audio_renderer::render(audio::pcm_buffer &buffer) {
    if (auto handler = impl_ptr<impl>()->_rendering_handler) {
        handler(buffer);
    }
}

void test_audio_renderer::set_sample_rate(double const sample_rate) {
    impl_ptr<impl>()->_sample_rate.set_value(sample_rate);
}

audio_renderable &test_audio_renderer::renderable() {
    if (!this->_renderable) {
        this->_renderable = audio_renderable{impl_ptr<impl>()};
    }
    return this->_renderable;
}
