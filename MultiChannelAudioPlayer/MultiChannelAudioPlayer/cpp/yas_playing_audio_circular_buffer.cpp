//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <mutex>
#include "yas_audio_format.h"
#include "yas_fast_each.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    enum buffer_state {
        unloaded,
        loading,
        loaded,
    };

    struct container {
        audio::pcm_buffer buffer;
        int64_t begin_frame;
        buffer_state state = buffer_state::unloaded;
    };

    struct context {
        int64_t play_frame;
    };

    impl(audio::format const &format, uint32_t const count) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            this->_containers.emplace_back(
                container{.buffer = audio::pcm_buffer{format, uint32_t(format.sample_rate())}});
        }
    }

    void read(audio::pcm_buffer &out_buffer) {
#warning todo bufferをロックして読み出す
    }

   private:
    std::vector<container> _containers;
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, uint32_t const count)
    : base(std::make_shared<impl>(format, count)) {
}

void audio_circular_buffer::read(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read(out_buffer);
}
