//
//  yas_playing_audio_buffer_container.cpp
//

#include "yas_playing_audio_buffer_container.h"

using namespace yas;
using namespace yas::playing;

audio_buffer_container::audio_buffer_container(audio::pcm_buffer &&buffer) : _buffer(std::move(buffer)) {
}

std::optional<int64_t> audio_buffer_container::file_idx() const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    return this->_file_idx;
}

std::optional<int64_t> audio_buffer_container::begin_frame() const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (auto const &file_idx = this->_file_idx) {
        return *file_idx * static_cast<int64_t>(this->_buffer.frame_length());
    } else {
        return std::nullopt;
    }
}

audio::format const &audio_buffer_container::format() const {
    return this->_buffer.format();
}

bool audio_buffer_container::contains(int64_t const frame) const {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (auto begin_frame_opt = this->begin_frame()) {
        int64_t const &begin_frame = *begin_frame_opt;
        return begin_frame <= frame && frame < (begin_frame + this->_buffer.frame_length());
    } else {
        return false;
    }
}

void audio_buffer_container::prepare_loading(int64_t const file_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    this->_state = state::unloaded;
    this->_file_idx = file_idx;
}

audio_buffer_container::write_result_t audio_buffer_container::load_from_file(audio::file &file,
                                                                              int64_t const file_idx) {
    std::lock_guard<std::recursive_mutex> lock(this->_mutex);

    if (this->_file_idx != file_idx) {
        return write_result_t{load_error::invalid_file_idx};
    }

    if (auto result = file.read_into_buffer(this->_buffer, this->_buffer.frame_length())) {
        this->_state = state::loaded;
        return write_result_t{nullptr};
    } else {
        return write_result_t{load_error::read_from_file_failed};
    }
}

audio_buffer_container::read_result_t audio_buffer_container::read_into_buffer(audio::pcm_buffer &to_buffer,
                                                                               uint32_t const to_frame,
                                                                               int64_t const play_frame,
                                                                               uint32_t const length) {
    auto lock = std::unique_lock<std::recursive_mutex>(this->_mutex, std::try_to_lock);
    if (!lock.owns_lock()) {
        return read_result_t{read_error::locked};
    }

    if (this->_state != state::loaded) {
        return read_result_t{read_error::unloaded};
    }

    auto begin_frame_opt = this->begin_frame();
    if (!begin_frame_opt.has_value()) {
        return read_result_t{read_error::begin_frame_not_found};
    }

    int64_t const begin_frame = *begin_frame_opt;
    int64_t const from_frame = play_frame - begin_frame;

    if (from_frame < 0 || begin_frame + this->_buffer.frame_length() <= from_frame) {
        return read_result_t{read_error::out_of_range_play_frame};
    }

    if (auto result = to_buffer.copy_from(this->_buffer, static_cast<uint32_t>(from_frame), to_frame, length)) {
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

std::string yas::to_string(audio_buffer_container::load_error const &error) {
    switch (error) {
        case audio_buffer_container::load_error::invalid_file_idx:
            return "invalid_file_idx";
        case audio_buffer_container::load_error::read_from_file_failed:
            return "read_from_file_failed";
    }
}

std::string yas::to_string(audio_buffer_container::read_error const &error) {
    switch (error) {
        case audio_buffer_container::read_error::locked:
            return "locked";
        case audio_buffer_container::read_error::unloaded:
            return "unloaded";
        case audio_buffer_container::read_error::begin_frame_not_found:
            return "begin_frame_not_found";
        case audio_buffer_container::read_error::out_of_range_play_frame:
            return "out_of_range_play_frame";
        case audio_buffer_container::read_error::copy_failed:
            return "copy_failed";
    }
}
