//
//  yas_playing_signal_file.cpp
//

#include "yas_playing_signal_file.h"
#include <fstream>
#include "yas_playing_timeline_utils.h"

using namespace yas;
using namespace yas::playing;

signal_file::signal_file(std::string const &path) : _path(path) {
}

signal_file::write_result_t signal_file::write(proc::signal_event const &event) {
    std::ofstream stream{this->_path, std::ios_base::out | std::ios_base::binary};
    if (!stream) {
        return write_result_t{error::open_stream_failed};
    }

    if (char const *data = timeline_utils::char_data(event)) {
        stream.write(data, event.byte_size());

        if (stream.fail()) {
            return write_result_t{error::write_to_stream_failed};
        }
    }

    stream.close();

    if (stream.fail()) {
        return write_result_t{error::close_stream_failed};
    }

    return write_result_t{nullptr};
}
