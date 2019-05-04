//
//  yas_playing_audio_channel_buffer.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <cpp_utils/yas_task.h>
#include <cpp_utils/yas_url.h>
#include <deque>
#include "yas_playing_audio_buffer_container.h"

namespace yas::playing {
struct audio_circular_buffer {
    using ptr = std::shared_ptr<audio_circular_buffer>;
    using wptr = std::weak_ptr<audio_circular_buffer>;

    void read_into_buffer(audio::pcm_buffer &out_buffer, int64_t const play_frame);
    void rotate_buffer(int64_t const next_frag_idx);
    void reload_all(int64_t const top_frag_idx);
    void reload(int64_t const frag_idx);

   protected:
    audio_circular_buffer(audio::format const &format, std::size_t const container_count, task_queue &&queue,
                          audio_buffer_container::load_f &&);

   private:
    uint32_t const _file_length;
    std::size_t const _container_count;
    audio_buffer_container::load_f const _load_handler;
    std::deque<audio_buffer_container::ptr> _containers;
    task_queue _queue;
    std::recursive_mutex _container_mutex;

    void _load_container(audio_buffer_container::ptr container_ptr, int64_t const file_idx);
};

audio_circular_buffer::ptr make_audio_circular_buffer(audio::format const &format, std::size_t const container_count,
                                                      task_queue queue, audio_buffer_container::load_f);
}  // namespace yas::playing
