//
//  yas_playing_audio_buffer_container.h
//

#pragma once

#include <audio/yas_audio_file.h>
#include <audio/yas_audio_format.h>
#include <audio/yas_audio_pcm_buffer.h>
#include <cpp_utils/yas_result.h>
#include <mutex>
#include <optional>
#include "yas_playing_types.h"

namespace yas::playing {
struct audio_buffer_container {
    using ptr = std::shared_ptr<audio_buffer_container>;
    using wptr = std::weak_ptr<audio_buffer_container>;

    enum class state {
        unloaded,
        loaded,
    };

    enum class load_error {
        fragment_idx_is_null,
        invalid_fragment_idx,
        write_buffer_failed,
    };

    enum class read_error {
        locked,
        unloaded,
        begin_frame_is_null,
        out_of_range_play_frame,
        out_of_range_length,
        copy_failed,
    };

    using load_result_t = result<std::nullptr_t, load_error>;
    using read_result_t = result<std::nullptr_t, read_error>;

    using load_f = std::function<bool(audio::pcm_buffer &buffer, int64_t const frag_idx)>;

    struct identifier : base {
        struct impl : base::impl {};
        identifier() : base(std::make_shared<impl>()) {
        }
    };

    identifier const identifier;

    [[nodiscard]] std::optional<fragment_index_t> fragment_idx() const;
    [[nodiscard]] std::optional<frame_index_t> begin_frame() const;
    [[nodiscard]] audio::format const &format() const;
    [[nodiscard]] bool contains(frame_index_t const frame) const;

    void prepare_loading(fragment_index_t const frag_idx);
    load_result_t load(fragment_index_t const frag_idx, load_f const &);
    read_result_t read_into_buffer(audio::pcm_buffer &to_buffer, frame_index_t const play_frame) const;

   protected:
    audio_buffer_container(audio::pcm_buffer &&buffer);

   private:
    audio::pcm_buffer _buffer;
    std::optional<fragment_index_t> _frag_idx = std::nullopt;
    state _state = state::unloaded;

    std::recursive_mutex mutable _mutex;
};

audio_buffer_container::ptr make_audio_buffer_container(audio::pcm_buffer &&buffer);
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::audio_buffer_container::state const &state);
std::string to_string(playing::audio_buffer_container::load_error const &error);
std::string to_string(playing::audio_buffer_container::read_error const &error);
}  // namespace yas

std::ostream &operator<<(std::ostream &, yas::playing::audio_buffer_container::state const &);
std::ostream &operator<<(std::ostream &, yas::playing::audio_buffer_container::load_error const &);
std::ostream &operator<<(std::ostream &, yas::playing::audio_buffer_container::read_error const &);
