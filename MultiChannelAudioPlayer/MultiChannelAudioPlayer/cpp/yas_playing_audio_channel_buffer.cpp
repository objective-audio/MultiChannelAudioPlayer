//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_channel_buffer.h"
#include "yas_audio_pcm_buffer.h"
#include "yas_fast_each.h"

using namespace yas;
using namespace yas::playing;

namespace yas::playing {
static uint32_t const buffer_count = 3;
}

struct audio_channel_buffer::impl : base::impl {
    std::vector<audio::pcm_buffer> _buffers;

    impl(audio::format const &format) {
        auto each = make_fast_each(buffer_count);
        while (yas_each_next(each)) {
            auto buffer = audio::pcm_buffer{format, uint32_t(format.sample_rate())};
        }
    }
};

audio_channel_buffer::audio_channel_buffer(audio::format const &format) : base(std::make_shared<impl>(format)) {
}
