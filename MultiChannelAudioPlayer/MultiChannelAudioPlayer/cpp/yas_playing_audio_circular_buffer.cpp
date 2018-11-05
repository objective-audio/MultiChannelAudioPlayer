//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <deque>
#include <mutex>
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_playing_audio_buffer_container.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    impl(audio::format const &format, std::size_t const count, url const &ch_url, operation_queue &&queue)
        : _file_length(static_cast<uint32_t>(format.sample_rate())),
          _ch_url(ch_url),
          _queue(std::move(queue)),
          _container_count(count) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto ptr = make_audio_buffer_container(audio::pcm_buffer{format, this->_file_length});
            this->_containers.push_back(std::move(ptr));
        }
    }

    void read_into_buffer(audio::pcm_buffer &out_buffer) {
        uint32_t remain = out_buffer.frame_length();

        while (remain > 0) {
            int64_t const current = this->_current_frame;
            int64_t const current_begin_frame = math::floor_int(current, this->_file_length);
            uint32_t const proc_length = std::min(static_cast<uint32_t>(current - current_begin_frame), remain);

            auto &container_ptr = this->_containers.front();

            uint32_t const to_frame = this->_file_length - remain;
            if (auto result = container_ptr->read_into_buffer(out_buffer, to_frame, current, proc_length);
                result.is_error()) {
                throw std::runtime_error("circular_buffer container read_info_buffer error : " +
                                         to_string(result.error()));
            }

            int64_t const next = current + proc_length;
            if (next % this->_file_length == 0) {
                int64_t const loading_file_idx =
                    (current_begin_frame + this->_file_length * this->_container_count) / this->_file_length;
                container_ptr->prepare_loading(loading_file_idx);
                this->_load_container(container_ptr, loading_file_idx);
            }

            remain -= proc_length;
            this->_current_frame += proc_length;
        }
    }

   private:
    url const _ch_url;
    uint32_t const _file_length;
    std::size_t const _container_count;
    std::deque<audio_buffer_container::ptr> _containers;
    operation_queue _queue;
    int64_t _current_frame;

    void _rotate_buffer() {
        auto &container_ptr = this->_containers.front();
        this->_containers.push_back(container_ptr);
        this->_containers.pop_front();
    }

    void _load_container(audio_buffer_container::ptr container_ptr, int64_t const file_idx) {
#warning todo operation_queueでファイルから読み込む
        operation op{[container_ptr](operation const &) {

        }};
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count, url const &ch_url,
                                             operation_queue queue)
    : base(std::make_shared<impl>(format, count, ch_url, std::move(queue))) {
}

audio_circular_buffer::audio_circular_buffer(std::nullptr_t) : base(nullptr) {
}

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read_into_buffer(out_buffer);
}
