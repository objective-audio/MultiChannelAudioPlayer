//
//  yas_playing_audio_renderer.cpp
//

#include "yas_playing_audio_renderer.h"

using namespace yas;
using namespace yas::playing;

struct audio_renderer::impl : base::impl, audio_renderable::impl {
    chaining::holder<double> _sample_rate{0.0};

    void set_rendering_handler(std::function<void(void)> &&) override {
    }
};

audio_renderer::audio_renderer() : base(std::make_shared<impl>()) {
}

audio_renderer::audio_renderer(std::nullptr_t) : base(nullptr) {
}
