//
//  yas_playing_audio_buffer_container.cpp
//

#include "yas_playing_audio_buffer_container.h"

using namespace yas;
using namespace yas::playing;

audio_buffer_container::audio_buffer_container(audio::pcm_buffer &&buffer) : _buffer(std::move(buffer)) {
}

std::optional<fragment_index_t> audio_buffer_container::fragment_idx() const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    return this->_frag_idx;
}

std::optional<frame_index_t> audio_buffer_container::begin_frame() const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (auto const &frag_idx = this->_frag_idx) {
        return *frag_idx * static_cast<frame_index_t>(this->_buffer.frame_length());
    } else {
        return std::nullopt;
    }
}

audio::format const &audio_buffer_container::format() const {
    return this->_buffer.format();
}

bool audio_buffer_container::contains(frame_index_t const frame) const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (auto begin_frame_opt = this->begin_frame()) {
        frame_index_t const &begin_frame = *begin_frame_opt;
        return begin_frame <= frame && frame < (begin_frame + this->_buffer.frame_length());
    } else {
        return false;
    }
}

void audio_buffer_container::prepare_loading(fragment_index_t const frag_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    this->_state = state::unloaded;
    this->_frag_idx = frag_idx;
}

audio_buffer_container::load_result_t audio_buffer_container::load(fragment_index_t const frag_idx,
                                                                   load_f const &handler) {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (!this->_frag_idx) {
        return load_result_t{load_error::fragment_idx_is_null};
    }

    if (*this->_frag_idx != frag_idx) {
        return load_result_t{load_error::invalid_fragment_idx};
    }

    if (handler(this->_buffer, frag_idx)) {
        this->_state = state::loaded;
        return load_result_t{nullptr};
    } else {
        return load_result_t{load_error::write_buffer_failed};
    }
}

audio_buffer_container::read_result_t audio_buffer_container::read_into_buffer(audio::pcm_buffer &to_buffer,
                                                                               frame_index_t const play_frame) const {
    auto lock = std::unique_lock<std::recursive_mutex>(this->_mutex, std::try_to_lock);
    if (!lock.owns_lock()) {
        return read_result_t{read_error::locked};
    }

    if (this->_state != state::loaded) {
        return read_result_t{read_error::unloaded};
    }

    auto begin_frame_opt = this->begin_frame();
    if (!begin_frame_opt.has_value()) {
        return read_result_t{read_error::begin_frame_is_null};
    }

    frame_index_t const begin_frame = *begin_frame_opt;
    frame_index_t const from_frame = play_frame - begin_frame;

    if (from_frame < 0 || this->_buffer.frame_length() <= from_frame) {
        return read_result_t{read_error::out_of_range_play_frame};
    }

    if (begin_frame + this->_buffer.frame_length() < play_frame + to_buffer.frame_length()) {
        return read_result_t{read_error::out_of_range_length};
    }

    if (auto result = to_buffer.copy_from(this->_buffer, {.from_begin_frame = static_cast<uint32_t>(from_frame),
                                                          .length = to_buffer.frame_length()})) {
        return read_result_t{nullptr};
    } else {
        return read_result_t{read_error::copy_failed};
    }
}

#pragma mark -

struct audio_buffer_container_factory : audio_buffer_container {
    audio_buffer_container_factory(audio::pcm_buffer &&buffer) : audio_buffer_container(std::move(buffer)) {
    }
};

audio_buffer_container::ptr playing::make_audio_buffer_container(audio::pcm_buffer &&buffer) {
    return std::make_shared<audio_buffer_container_factory>(std::move(buffer));
}

#pragma mark -

std::string yas::to_string(playing::audio_buffer_container::state const &state) {
    switch (state) {
        case audio_buffer_container::state::loaded:
            return "loaded";
        case audio_buffer_container::state::unloaded:
            return "unloaded";
    }
}

std::string yas::to_string(audio_buffer_container::load_error const &error) {
    switch (error) {
        case audio_buffer_container::load_error::fragment_idx_is_null:
            return "file_idx_is_null";
        case audio_buffer_container::load_error::invalid_fragment_idx:
            return "invalid_file_idx";
        case audio_buffer_container::load_error::write_buffer_failed:
            return "write_buffer_failed";
    }
}

std::string yas::to_string(audio_buffer_container::read_error const &error) {
    switch (error) {
        case audio_buffer_container::read_error::locked:
            return "locked";
        case audio_buffer_container::read_error::unloaded:
            return "unloaded";
        case audio_buffer_container::read_error::begin_frame_is_null:
            return "begin_frame_not_found";
        case audio_buffer_container::read_error::out_of_range_play_frame:
            return "out_of_range_play_frame";
        case audio_buffer_container::read_error::out_of_range_length:
            return "out_of_range_length";
        case audio_buffer_container::read_error::copy_failed:
            return "copy_failed";
    }
}

std::ostream &operator<<(std::ostream &os, yas::playing::audio_buffer_container::state const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::playing::audio_buffer_container::load_error const &value) {
    os << to_string(value);
    return os;
}

std::ostream &operator<<(std::ostream &os, yas::playing::audio_buffer_container::read_error const &value) {
    os << to_string(value);
    return os;
}
