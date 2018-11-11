//
//  yas_playing_audio_renderer.cpp
//

#include "yas_playing_audio_renderer.h"

using namespace yas;
using namespace yas::playing;

struct audio_renderer::impl : base::impl, audio_renderable::impl {
    chaining::holder<double> _sample_rate{0.0};
    audio_renderable::rendering_f _rendering_handler;

    void set_rendering_handler(audio_renderable::rendering_f &&handler) override {
        this->_rendering_handler = std::move(handler);
    }
};

audio_renderer::audio_renderer() : base(std::make_shared<impl>()) {
}

audio_renderer::audio_renderer(std::nullptr_t) : base(nullptr) {
}
