//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <cpp_utils/yas_fast_each.h>
#include <mutex>
#include "yas_playing_math.h"
#include "yas_playing_path.h"
#include "yas_playing_types.h"

using namespace yas;
using namespace yas::playing;

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count, task_queue &&queue,
                                             audio_buffer_container::load_f &&load_handler)
    : _frag_length(static_cast<length_t>(format.sample_rate())),
      _queue(std::move(queue)),
      _container_count(count),
      _load_handler_ptr(std::make_shared<audio_buffer_container::load_f>(std::move(load_handler))) {
    auto each = make_fast_each(count);
    while (yas_each_next(each)) {
        auto ptr = make_audio_buffer_container(audio::pcm_buffer{format, static_cast<uint32_t>(this->_frag_length)});
        this->_containers.push_back(std::move(ptr));
    }
}

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer, frame_index_t const play_frame) {
    auto lock = std::unique_lock<std::recursive_mutex>(this->_container_mutex, std::try_to_lock);
    if (!lock.owns_lock()) {
        return;
    }

    auto &container_ptr = this->_containers.front();

    container_ptr->read_into_buffer(out_buffer, play_frame);
}

void audio_circular_buffer::rotate_buffer(fragment_index_t const next_frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    auto &container_ptr = this->_containers.front();

    if (container_ptr->fragment_idx() == next_frag_idx - 1) {
        this->_containers.push_back(container_ptr);
        this->_containers.pop_front();
        fragment_index_t const loading_frag_idx = next_frag_idx + this->_container_count - 1;
        container_ptr->prepare_loading(loading_frag_idx);
        this->_load_container(container_ptr, loading_frag_idx);
    } else {
        this->reload_all(next_frag_idx);
    }
}

void audio_circular_buffer::reload_all(fragment_index_t const top_frag_idx) {
    fragment_index_t load_frag_idx = top_frag_idx;

    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    for (auto &container_ptr : this->_containers) {
        container_ptr->prepare_loading(load_frag_idx);
        this->_load_container(container_ptr, load_frag_idx);
        ++load_frag_idx;
    }
}

void audio_circular_buffer::reload(fragment_index_t const frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    for (auto &container_ptr : this->_containers) {
        if (auto const frag_idx_opt = container_ptr->fragment_idx(); *frag_idx_opt == frag_idx) {
            container_ptr->prepare_loading(frag_idx);
            this->_load_container(container_ptr, frag_idx);
        }
    }
}

void audio_circular_buffer::_load_container(audio_buffer_container::ptr container_ptr,
                                            fragment_index_t const frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_container_mutex);

    task task{[container_ptr, frag_idx, load_handler_ptr = this->_load_handler_ptr](yas::task const &) {
                  auto load_result = container_ptr->load(frag_idx, *load_handler_ptr);
#warning todo エラーハンドリングする？
              },
              task_option_t{.push_cancel_id = container_ptr->identifier,
                            .priority = static_cast<std::size_t>(queue_priority::playing)}};

    this->_queue.push_back(std::move(task));
}

#pragma mark -

namespace yas::playing {
struct audio_circular_buffer_factory : audio_circular_buffer {
    audio_circular_buffer_factory(audio::format const &format, std::size_t const container_count, task_queue &&queue,
                                  audio_buffer_container::load_f &&handler)
        : audio_circular_buffer(format, container_count, std::move(queue), std::move(handler)) {
    }
};
}  // namespace yas::playing

audio_circular_buffer::ptr playing::make_audio_circular_buffer(audio::format const &format,
                                                               std::size_t const container_count, task_queue queue,
                                                               audio_buffer_container::load_f handler) {
    return std::make_shared<audio_circular_buffer_factory>(format, container_count, std::move(queue),
                                                           std::move(handler));
}
