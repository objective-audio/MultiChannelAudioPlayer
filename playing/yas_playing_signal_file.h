//
//  yas_playing_signal_file.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <cpp_utils/yas_result.h>
#include <processing/yas_processing_signal_event.h>
#include <processing/yas_processing_time.h>
#include <string>
#include "yas_playing_signal_file_info.h"
#include "yas_playing_types.h"

namespace yas::playing::signal_file {
enum class write_error {
    open_stream_failed,
    write_to_stream_failed,
    close_stream_failed,
};

enum class read_error {
    invalid_sample_type,
    out_of_range,
    open_stream_failed,
    read_from_stream_failed,
    read_count_not_match,
    close_stream_failed,
};

using write_result_t = result<std::nullptr_t, write_error>;
using read_result_t = result<std::nullptr_t, read_error>;

write_result_t write(std::string const &path, proc::signal_event const &event);
read_result_t read(std::string const &path, void *data_ptr, std::size_t const byte_length);
read_result_t read(signal_file_info const &, audio::pcm_buffer &, playing::frame_index_t const buf_top_frame);
}  // namespace yas::playing::signal_file
