//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include "yas_audio_pcm_buffer.h"
#include "yas_fast_each.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    std::vector<audio::pcm_buffer> _buffers;

    impl(audio::format const &format, uint32_t const count) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            this->_buffers.emplace_back(audio::pcm_buffer{format, uint32_t(format.sample_rate())});
        }
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, uint32_t const count)
    : base(std::make_shared<impl>(format, count)) {
}
