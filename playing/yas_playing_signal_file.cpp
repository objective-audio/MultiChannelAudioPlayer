//
//  yas_playing_signal_file.cpp
//

#include "yas_playing_signal_file.h"
#include <audio/yas_audio_format.h>
#include <audio/yas_audio_types.h>
#include <fstream>
#include "yas_playing_timeline_utils.h"

using namespace yas;
using namespace yas::playing;

signal_file::write_result_t signal_file::write(std::string const &path, proc::signal_event const &event) {
    std::ofstream stream{path, std::ios_base::out | std::ios_base::binary};
    if (!stream) {
        return write_result_t{write_error::open_stream_failed};
    }

    if (char const *data = timeline_utils::char_data(event)) {
        stream.write(data, event.byte_size());

        if (stream.fail()) {
            return write_result_t{write_error::write_to_stream_failed};
        }
    }

    stream.close();

    if (stream.fail()) {
        return write_result_t{write_error::close_stream_failed};
    }

    return write_result_t{nullptr};
}

signal_file::read_result_t signal_file::read(std::string const &path, void *data_ptr, std::size_t const length) {
    auto stream = std::fstream{path, std::ios_base::in | std::ios_base::binary};
    if (!stream) {
        return read_result_t{read_error::open_stream_failed};
    }

    stream.read(reinterpret_cast<char *>(data_ptr), length);
    if (stream.fail()) {
        return read_result_t{read_error::read_from_stream_failed};
    }

    if (stream.gcount() != length) {
        return read_result_t{read_error::read_count_not_match};
    }

    stream.close();
    if (stream.fail()) {
        return read_result_t{read_error::close_stream_failed};
    }

    return read_result_t{nullptr};
}

signal_file::read_result_t signal_file::read(signal_file_info const &info, audio::pcm_buffer &buffer,
                                             playing::frame_index_t const buf_top_frame) {
    if (info.sample_type != yas::to_sample_type(buffer.format().pcm_format())) {
        return read_result_t{read_error::invalid_sample_type};
    }

    frame_index_t const buf_next_frame = buf_top_frame + buffer.frame_length();

    if (info.range.frame < buf_top_frame || buf_next_frame < info.range.next_frame()) {
        return read_result_t{read_error::out_of_range};
    }

    std::size_t const sample_byte_count = buffer.format().sample_byte_count();
    frame_index_t const frame = (info.range.frame - buf_top_frame) * sample_byte_count;
    length_t const length = info.range.length * sample_byte_count;
    char *data_ptr = timeline_utils::char_data(buffer);

    return read(info.path, &data_ptr[frame], length);
}
