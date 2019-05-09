//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <cpp_utils/yas_task.h>
#include <deque>
#include "yas_playing_audio_buffer_container.h"

namespace yas::playing {
struct audio_circular_buffer {
    using ptr = std::shared_ptr<audio_circular_buffer>;
    using wptr = std::weak_ptr<audio_circular_buffer>;

    void read_into_buffer(audio::pcm_buffer &out_buffer, frame_index_t const play_frame);
    void rotate_buffer(fragment_index_t const next_frag_idx);
    void reload_all(fragment_index_t const top_frag_idx);
    void reload(fragment_index_t const frag_idx);

   protected:
    audio_circular_buffer(audio::format const &format, std::size_t const container_count, task_queue &&queue,
                          audio_buffer_container::load_f &&);

   private:
    uint32_t const _frag_length;
    std::size_t const _container_count;
    std::shared_ptr<audio_buffer_container::load_f> const _load_handler_ptr;
    std::deque<audio_buffer_container::ptr> _containers;
    task_queue _queue;
    std::recursive_mutex _container_mutex;

    void _load_container(audio_buffer_container::ptr container_ptr, fragment_index_t const frag_idx);
};

audio_circular_buffer::ptr make_audio_circular_buffer(audio::format const &format, std::size_t const container_count,
                                                      task_queue queue, audio_buffer_container::load_f);
}  // namespace yas::playing
