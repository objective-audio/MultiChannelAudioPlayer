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
    read_frame_failed,
    read_sample_store_type_failed,
    read_value_failed,
    sample_store_type_not_found,
};

using event_map_t = std::multimap<playing::frame_index_t, proc::number_event>;
using write_result_t = result<std::nullptr_t, write_error>;
using read_result_t = result<event_map_t, read_error>;

write_result_t write(std::string const &path, event_map_t const &);
read_result_t read(std::string const &path);
}  // namespace yas::playing::numbers_file
