//
//  yas_playing_numbers_file.cpp
//

#include "yas_playing_numbers_file.h"
#include <fstream>
#include "yas_playing_timeline_utils.h"

using namespace yas;
using namespace yas::playing;

numbers_file::write_result_t numbers_file::write(
    std::string const &path, std::multimap<playing::frame_index_t, proc::number_event> const &events) {
    std::ofstream stream{path, std::ios_base::out | std::ios_base::binary};
    if (!stream) {
        return write_result_t{write_error::open_stream_failed};
    }

    for (auto const &event_pair : events) {
        proc::time::frame::type const &frame = event_pair.first;

        if (char const *data = timeline_utils::char_data(frame)) {
            stream.write(data, sizeof(proc::time::frame::type));
            if (stream.fail()) {
                return write_result_t{write_error::write_to_stream_failed};
            }
        }

        proc::number_event const &event = event_pair.second;

        auto const store_type = timeline_utils::to_sample_store_type(event.sample_type());
        if (char const *data = timeline_utils::char_data(store_type)) {
            stream.write(data, sizeof(sample_store_type));
            if (stream.fail()) {
                return write_result_t{write_error::write_to_stream_failed};
            }
        }

        if (char const *data = timeline_utils::char_data(event)) {
            stream.write(data, event.sample_byte_count());
            if (stream.fail()) {
                return write_result_t{write_error::write_to_stream_failed};
            }
        }
    }

    stream.close();
    if (stream.fail()) {
        return write_result_t{write_error::close_stream_failed};
    }

    return write_result_t{nullptr};
}

numbers_file::read_result_t numbers_file::read(std::string const &path) {
    std::ofstream stream{path, std::ios_base::in | std::ios_base::binary};
    if (!stream) {
        return read_result_t{read_error::open_stream_failed};
    }

#warning todo

    stream.close();
    if (stream.fail()) {
        return read_result_t{read_error::close_stream_failed};
    }

    return read_result_t{nullptr};
}
