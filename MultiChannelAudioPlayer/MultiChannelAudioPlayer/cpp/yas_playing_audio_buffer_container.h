//
//  yas_playing_audio_buffer_container.h
//

#pragma once

#include <mutex>
#include <optional>
#include "yas_audio_file.h"
#include "yas_audio_format.h"
#include "yas_audio_pcm_buffer.h"
#include "yas_result.h"

namespace yas::playing {
struct audio_buffer_container {
    using ptr = std::shared_ptr<audio_buffer_container>;
    using wptr = std::weak_ptr<audio_buffer_container>;

    enum state {
        unloaded,
        loaded,
    };

    enum class load_error {
        file_idx_is_null,
        invalid_file_idx,
        read_from_file_failed,
    };

    enum class read_error {
        locked,
        unloaded,
        begin_frame_is_null,
        out_of_range_play_frame,
        copy_failed,
    };

    using load_result_t = result<std::nullptr_t, load_error>;
    using read_result_t = result<std::nullptr_t, read_error>;

    std::optional<int64_t> file_idx() const;
    std::optional<int64_t> begin_frame() const;
    audio::format const &format() const;
    bool contains(int64_t const frame) const;

    void prepare_loading(int64_t const file_idx);
    load_result_t load_from_file(audio::file &, int64_t const file_idx);
    read_result_t read_into_buffer(audio::pcm_buffer &to_buffer, uint32_t const to_frame, int64_t const play_frame,
                                   uint32_t const length);

   protected:
    audio_buffer_container(audio::pcm_buffer &&buffer);

   private:
    audio::pcm_buffer _buffer;
    std::optional<int64_t> _file_idx = std::nullopt;
    state _state = state::unloaded;

    std::recursive_mutex mutable _mutex;
};

audio_buffer_container::ptr make_audio_buffer_container(audio::pcm_buffer &&buffer);
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::audio_buffer_container::load_error const &error);
std::string to_string(playing::audio_buffer_container::read_error const &error);
}  // namespace yas
