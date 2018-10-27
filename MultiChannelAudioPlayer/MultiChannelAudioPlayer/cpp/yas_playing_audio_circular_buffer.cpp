//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <mutex>
#include "yas_audio_pcm_buffer.h"
#include "yas_fast_each.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    enum buffer_state {
        unloaded,
        loading,
        loaded,
    };

    struct buffer {
        audio::pcm_buffer buffer;
        buffer_state state = buffer_state::unloaded;
    };

    struct context {
        int64_t play_frame;
    };

    std::vector<buffer> _buffers;
    std::recursive_mutex _mutex;

    impl(audio::format const &format, uint32_t const count) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            this->_buffers.emplace_back(buffer{.buffer = audio::pcm_buffer{format, uint32_t(format.sample_rate())}});
        }
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, uint32_t const count)
    : base(std::make_shared<impl>(format, count)) {
}
