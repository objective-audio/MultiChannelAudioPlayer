//
//  yas_playing_audio_buffers.cpp
//

#include "yas_playing_audio_buffer_manager.h"
#include "yas_fast_each.h"
#include "yas_playing_audio_circular_buffer.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_buffer_manager::impl : base::impl {
    impl(double const sample_rate, audio::pcm_format const pcm_format, std::size_t const ch_count, url const &root_url)
        : _format({.sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url) {
        auto each = make_fast_each(static_cast<uint32_t>(ch_count));
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            this->_ch_buffers.emplace_back(
                audio_circular_buffer{this->_format, 3, url_utils::channel_url(this->_root_url, idx), this->_queue});
        }
    }

   private:
    audio::format const _format;
    url const _root_url;
    std::vector<audio_circular_buffer> _ch_buffers;
    operation_queue _queue;
};

audio_buffer_manager::audio_buffer_manager(double const sample_rate, audio::pcm_format const pcm_format,
                                           std::size_t const ch_count, url const &root_url)
    : base(std::make_shared<impl>(sample_rate, pcm_format, ch_count, root_url)) {
}
