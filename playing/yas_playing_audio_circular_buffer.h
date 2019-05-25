//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_task.h>
#include <deque>
#include "yas_playing_audio_buffer_container.h"

namespace yas::playing {
struct audio_circular_buffer : std::enable_shared_from_this<audio_circular_buffer> {
    using ptr = std::shared_ptr<audio_circular_buffer>;
    using wptr = std::weak_ptr<audio_circular_buffer>;

    using state_map_t = std::map<fragment_index_t, audio_buffer_container::state>;
    using state_map_holder_t = chaining::map::holder<fragment_index_t, audio_buffer_container::state>;

    void read_into_buffer(audio::pcm_buffer &out_buffer, frame_index_t const play_frame);
    void rotate_buffer(fragment_index_t const next_frag_idx);
    void reload_all(fragment_index_t const top_frag_idx);
    void reload(fragment_index_t const frag_idx);

    state_map_t const &states() const;
    state_map_holder_t::chain_t states_chain() const;

   protected:
    audio_circular_buffer(audio::format const &format, std::size_t const container_count, task_queue &&queue,
                          audio_buffer_container::load_f &&);

   private:
    length_t const _frag_length;
    std::size_t const _container_count;
    std::shared_ptr<audio_buffer_container::load_f> const _load_handler_ptr;
    std::deque<audio_buffer_container::ptr> _containers;
    task_queue _queue;
    std::recursive_mutex _containers_mutex;
    std::recursive_mutex _loading_mutex;
    state_map_holder_t _states_holder;

    void _load_container(audio_buffer_container::ptr container_ptr, fragment_index_t const frag_idx);
    void _rotate_containers();
    audio_buffer_container::ptr const &_front_container();
    void _set_state_on_main(audio_buffer_container::state const, fragment_index_t const);
};

audio_circular_buffer::ptr make_audio_circular_buffer(audio::format const &format, std::size_t const container_count,
                                                      task_queue queue, audio_buffer_container::load_f);
}  // namespace yas::playing
