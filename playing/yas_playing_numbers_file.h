//
//  yas_playing_numbers_file.h
//

#pragma once

#include <cpp_utils/yas_result.h>
#include <processing/yas_processing_number_event.h>
#include <string>
#include "yas_playing_types.h"

namespace yas::playing {
struct numbers_file {
    enum class error {
        open_stream_failed,
        write_to_stream_failed,
        close_stream_failed,
    };

    using write_result_t = result<std::nullptr_t, error>;

    numbers_file(std::string const &);

    write_result_t write(std::multimap<playing::frame_index_t, proc::number_event> const &);

   private:
    std::string const path;
};
}  // namespace yas::playing
