//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_thread.h>
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
    if (auto const &container_ptr = this->_front_container()) {
        container_ptr->read_into_buffer(out_buffer, play_frame);
    }
}

void audio_circular_buffer::rotate_buffer(fragment_index_t const next_frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_loading_mutex);

    if (auto &container_ptr = this->_containers.front(); container_ptr->fragment_idx() == next_frag_idx - 1) {
        this->_rotate_containers();
        fragment_index_t const loading_frag_idx = next_frag_idx + this->_container_count - 1;
        this->_load_container(container_ptr, loading_frag_idx);
    } else {
        this->reload_all(next_frag_idx);
    }
}

void audio_circular_buffer::reload_all(fragment_index_t const top_frag_idx) {
    fragment_index_t load_frag_idx = top_frag_idx;

    std::lock_guard<std::recursive_mutex> lock(this->_loading_mutex);

    for (auto &container_ptr : this->_containers) {
        this->_load_container(container_ptr, load_frag_idx);
        ++load_frag_idx;
    }
}

void audio_circular_buffer::reload(fragment_index_t const frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_loading_mutex);

    for (auto &container_ptr : this->_containers) {
        if (auto const frag_idx_opt = container_ptr->fragment_idx(); *frag_idx_opt == frag_idx) {
            this->_load_container(container_ptr, frag_idx);
        }
    }
}

void audio_circular_buffer::_load_container(audio_buffer_container::ptr container_ptr,
                                            fragment_index_t const frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_loading_mutex);

    this->_set_state_on_main(audio_buffer_container::state::unloaded, frag_idx);

    container_ptr->prepare_loading(frag_idx);

    audio_circular_buffer::wptr weak = this->shared_from_this();

    task task{[weak, container_ptr, frag_idx, load_handler_ptr = this->_load_handler_ptr](yas::task const &) {
                  if (auto load_result = container_ptr->load(frag_idx, *load_handler_ptr)) {
                      if (auto shared = weak.lock()) {
                          shared->_set_state_on_main(audio_buffer_container::state::loaded, frag_idx);
                      }
                  }
              },
              task_option_t{.push_cancel_id = container_ptr->identifier,
                            .priority = static_cast<std::size_t>(queue_priority::playing)}};

    this->_queue.push_back(std::move(task));
}

audio_buffer_container::ptr const &audio_circular_buffer::_front_container() {
    auto lock = std::unique_lock<std::recursive_mutex>(this->_containers_mutex, std::try_to_lock);
    if (lock.owns_lock()) {
        return this->_containers.front();
    } else {
        static audio_buffer_container::ptr const _empty{nullptr};
        return _empty;
    }
}

void audio_circular_buffer::_rotate_containers() {
    std::lock_guard<std::recursive_mutex> lock(this->_containers_mutex);
    this->_containers.push_back(this->_containers.front());
    this->_containers.pop_front();
}

void audio_circular_buffer::_set_state_on_main(audio_buffer_container::state const state,
                                               fragment_index_t const frag_idx) {
    audio_circular_buffer::wptr weak = this->shared_from_this();
    auto handler = [weak, state, frag_idx]() {
        if (auto shared = weak.lock()) {
            if (state == audio_buffer_container::state::loaded) {
                shared->_states_holder.insert_or_replace(frag_idx, state);
            } else {
                shared->_states_holder.erase_for_key(frag_idx);
            }
        }
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        handler();
    });
}

audio_circular_buffer::state_map_t const &audio_circular_buffer::states() const {
    assert(thread::is_main());
    return this->_states_holder.raw();
}

audio_circular_buffer::state_map_holder_t::chain_t audio_circular_buffer::states_chain() const {
    assert(thread::is_main());
    return this->_states_holder.chain();
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
