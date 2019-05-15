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

void signal_file::write(proc::time::range const &range, proc::signal_event const &event) {
    std::ofstream stream{this->_path, std::ios_base::out | std::ios_base::binary};
    if (!stream) {
        //        return error::open_signal_stream_failed;
    }

    if (char const *data = timeline_utils::char_data(event)) {
        stream.write(data, event.byte_size());
    }

    stream.close();
}
