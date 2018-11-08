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

    // 必ず1秒バッファひとつの範囲にする
    void read_into_buffer(audio::pcm_buffer &out_buffer, int64_t const play_frame) {
        auto lock = std::unique_lock<std::recursive_mutex>(this->_container_mutex, std::try_to_lock);
        if (!lock.owns_lock()) {
            return;
        }

        auto &container_ptr = this->_containers.front();

        container_ptr->read_into_buffer(out_buffer, 0, play_frame, out_buffer.frame_length());
    }

    void seek(int64_t const seek_frame) {
        this->_queue.cancel();

        int64_t const seek_begin_frame = math::floor_int(seek_frame, this->_file_length);
        int64_t load_file_idx = seek_begin_frame / this->_file_length;

        std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

        for (auto &container_ptr : this->_containers) {
            container_ptr->prepare_loading(load_file_idx);
            this->_load_container(container_ptr, load_file_idx);
            ++load_file_idx;
        }
    }

   private:
    url const _ch_url;
    uint32_t const _file_length;
    std::size_t const _container_count;
    std::deque<audio_buffer_container::ptr> _containers;
    operation_queue _queue;
    std::recursive_mutex _container_mutex;

    void _rotate_buffer() {
        std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

        auto &container_ptr = this->_containers.front();

        auto file_idx_opt = container_ptr->file_idx();
        if (!file_idx_opt) {
            return;
        }
        auto const load_file_idx = *file_idx_opt + 1;

        this->_containers.push_back(container_ptr);
        this->_containers.pop_front();

        container_ptr->prepare_loading(load_file_idx);
        this->_load_container(container_ptr, load_file_idx);
    }

    void _load_container(audio_buffer_container::ptr container_ptr, int64_t const file_idx) {
        std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

        auto file_url = playing::url_utils::caf_url(this->_ch_url, file_idx);

        operation op{[container_ptr, file_url = std::move(file_url), file_idx](operation const &) {
                         auto file_result = audio::make_opened_file(audio::file::open_args{
                             .file_url = file_url,
                             .pcm_format = container_ptr->format().pcm_format(),
                             .interleaved = false,
                         });

                         auto &file = file_result.value();

                         auto load_result = container_ptr->load_from_file(file, file_idx);
                     },
                     operation_option_t{.push_cancel_id = container_ptr->identifier}};

        this->_queue.push_back(std::move(op));
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count, url const &ch_url,
                                             operation_queue queue)
    : base(std::make_shared<impl>(format, count, ch_url, std::move(queue))) {
}

audio_circular_buffer::audio_circular_buffer(std::nullptr_t) : base(nullptr) {
}

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer, int64_t const play_frame) {
    impl_ptr<impl>()->read_into_buffer(out_buffer, play_frame);
}

void audio_circular_buffer::seek(int64_t const seek_frame) {
    impl_ptr<impl>()->seek(seek_frame);
}
