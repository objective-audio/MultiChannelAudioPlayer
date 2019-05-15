//
//  yas_playing_signal_file.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <processing/yas_processing_signal_event.h>
#include <processing/yas_processing_time.h>
#include <string>

namespace yas::playing::signal_file {
enum class error {
    open_stream_failed,
    write_to_stream_failed,
    close_stream_failed,
};

using write_result_t = result<std::nullptr_t, error>;

write_result_t write(std::string const &path, proc::signal_event const &event);
}  // namespace yas::playing::signal_file
