//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <mutex>
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count, url const &ch_url,
                                             operation_queue queue)
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

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer, int64_t const play_frame) {
    auto lock = std::unique_lock<std::recursive_mutex>(this->_container_mutex, std::try_to_lock);
    if (!lock.owns_lock()) {
        return;
    }

    auto &container_ptr = this->_containers.front();

    container_ptr->read_into_buffer(out_buffer, play_frame);
}

void audio_circular_buffer::rotate_buffer(int64_t const next_file_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    auto &container_ptr = this->_containers.front();

    if (container_ptr->file_idx() == next_file_idx - this->_container_count) {
        this->_containers.push_back(container_ptr);
        this->_containers.pop_front();
        container_ptr->prepare_loading(next_file_idx);
        this->_load_container(container_ptr, next_file_idx);
    } else {
        this->reload_all(next_file_idx);
    }
}

void audio_circular_buffer::reload_all(int64_t const top_file_idx) {
    this->_queue.cancel();

    int64_t load_file_idx = top_file_idx;

    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    for (auto &container_ptr : this->_containers) {
        container_ptr->prepare_loading(load_file_idx);
        this->_load_container(container_ptr, load_file_idx);
        ++load_file_idx;
    }
}

void audio_circular_buffer::reload(int64_t const file_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    for (auto &container_ptr : this->_containers) {
        if (auto const file_idx_opt = container_ptr->file_idx(); *file_idx_opt == file_idx) {
            container_ptr->prepare_loading(file_idx);
            this->_load_container(container_ptr, file_idx);
        }
    }
}

void audio_circular_buffer::_load_container(audio_buffer_container::ptr container_ptr, int64_t const file_idx) {
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

#pragma mark -

audio_circular_buffer::ptr playing::make_audio_circular_buffer(audio::format const &format,
                                                               std::size_t const container_count, url const &ch_url,
                                                               operation_queue queue) {
    return std::make_shared<audio_circular_buffer>(format, container_count, ch_url, std::move(queue));
}
