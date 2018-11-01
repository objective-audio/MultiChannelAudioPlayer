//
//  yas_playing_audio_buffer_container.h
//

#pragma once

#include <mutex>
#include "yas_audio_file.h"
#include "yas_audio_format.h"
#include "yas_audio_pcm_buffer.h"
#include "yas_result.h"

namespace yas::playing {
struct audio_buffer_container {
    enum state {
        unloaded,
        loaded,
    };

    enum class write_error {
        read_from_file_failed,
    };

    enum class read_error {
        locked,
        unloaded,
        out_of_range_play_frame,
        copy_failed,
    };

    using write_result_t = result<std::nullptr_t, write_error>;
    using read_result_t = result<std::nullptr_t, read_error>;

    audio_buffer_container(audio::pcm_buffer &&buffer);

    int64_t file_idx() const;
    audio::format const &format() const;
    bool contains(int64_t const frame);

    void prepare_loading(int64_t const frame);
    write_result_t write_from_file(audio::file &);
    read_result_t read_into_buffer(audio::pcm_buffer &to_buffer, uint32_t const to_frame, int64_t const play_frame,
                                   uint32_t const length);

   private:
    audio::pcm_buffer _buffer;
    int64_t _begin_frame;
    state _state = state::unloaded;

    std::recursive_mutex mutable _mutex;
};
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::audio_buffer_container::write_error const &error);
std::string to_string(playing::audio_buffer_container::read_error const &error);
}  // namespace yas
