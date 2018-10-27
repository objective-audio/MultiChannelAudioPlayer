//
//  yas_playing_audio_buffers.cpp
//

#include "yas_playing_audio_buffer_manager.h"
#include "yas_fast_each.h"
#include "yas_playing_audio_circular_buffer.h"

using namespace yas;
using namespace yas::playing;

struct audio_buffer_manager::impl : base::impl {
    audio::format const _format;
    std::vector<audio_circular_buffer> _ch_buffers;

    impl(double const sample_rate, audio::pcm_format const pcm_format, std::size_t const ch_count)
        : _format({.sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}) {
        auto each = make_fast_each(ch_count);
        while (yas_each_next(each)) {
            this->_ch_buffers.emplace_back(audio_circular_buffer{this->_format, 3});
        }
    }
};

audio_buffer_manager::audio_buffer_manager(double const sample_rate, audio::pcm_format const pcm_format,
                                           std::size_t const ch_count)
    : base(std::make_shared<impl>(sample_rate, pcm_format, ch_count)) {
}
