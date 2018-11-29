//
//  yas_playing_test_audio_renderer.cpp
//

#include "yas_playing_test_audio_renderer.h"
#include "yas_audio_format.h"

using namespace yas;
using namespace yas::playing;
using namespace yas::playing::test_utils;

struct test_audio_renderer::impl : base::impl, audio_renderable::impl {
    chaining::holder<double> _sample_rate{0.0};
    chaining::holder<audio::pcm_format> _pcm_format{audio::pcm_format::float32};
    chaining::holder<uint32_t> _channel_count{uint32_t(0)};
    std::atomic<bool> _is_rendering = false;
    audio_renderable::rendering_f _rendering_handler;
    std::recursive_mutex _rendering_mutex;

    void set_rendering_handler(audio_renderable::rendering_f &&handler) override {
        std::lock_guard<std::recursive_mutex> lock(this->_rendering_mutex);
        this->_rendering_handler = std::move(handler);
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

    void render(audio::pcm_buffer &buffer) {
        if (!this->_is_rendering.load()) {
            return;
        }

        auto const &format = buffer.format();

        if (format.is_interleaved()) {
            throw std::invalid_argument("buffer is not non-interleaved.");
        }

        if (this->_channel_count.value() != buffer.format().channel_count()) {
            throw std::invalid_argument("buffers channel_count is not equal to channel_count.");
        }

        if (auto lock = std::unique_lock<std::recursive_mutex>(this->_rendering_mutex, std::try_to_lock);
            lock.owns_lock()) {
            if (auto const &handler = this->_rendering_handler) {
                handler(buffer);
            }
        }
    }
};

test_audio_renderer::test_audio_renderer() : base(std::make_shared<impl>()) {
}

test_audio_renderer::test_audio_renderer(std::nullptr_t) : base(nullptr) {
}

void test_audio_renderer::set_pcm_format(audio::pcm_format const pcm_fomat) {
    impl_ptr<impl>()->_pcm_format.set_value(pcm_fomat);
}

void test_audio_renderer::set_channel_count(uint32_t const ch_count) {
    impl_ptr<impl>()->_channel_count.set_value(ch_count);
}

void test_audio_renderer::set_sample_rate(double const sample_rate) {
    impl_ptr<impl>()->_sample_rate.set_value(sample_rate);
}

void test_audio_renderer::render(audio::pcm_buffer &buffer) {
    impl_ptr<impl>()->render(buffer);
}

audio_renderable &test_audio_renderer::renderable() {
    if (!this->_renderable) {
        this->_renderable = audio_renderable{impl_ptr<impl>()};
    }
    return this->_renderable;
}
