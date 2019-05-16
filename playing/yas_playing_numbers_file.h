//
//  yas_playing_numbers_file.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <processing/yas_processing_number_event.h>
#include <string>
#include "yas_playing_types.h"

namespace yas::playing::numbers_file {
enum class write_error {
    open_stream_failed,
    write_to_stream_failed,
    close_stream_failed,
};

enum class read_error {
    open_stream_failed,
    read_from_stream_failed,
    close_stream_failed,
};

using write_result_t = result<std::nullptr_t, write_error>;
using read_result_t = result<std::nullptr_t, read_error>;

write_result_t write(std::string const &, std::multimap<playing::frame_index_t, proc::number_event> const &);
read_result_t read(std::string const &);
}  // namespace yas::playing::numbers_file
