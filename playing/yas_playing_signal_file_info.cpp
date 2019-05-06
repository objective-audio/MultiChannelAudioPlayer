//
//  yas_playing_signal_file_info.cpp
//

#include "yas_playing_signal_file_info.h"
#include "yas_playing_path_utils.h"

using namespace yas;
using namespace yas::playing;

signal_file_info::signal_file_info(proc::time::range const &range, std::type_info const &sample_type)
    : range(range), sample_type(sample_type) {
}

std::string signal_file_info::file_name() const {
    return path_utils::signal_file_name(this->range, this->sample_type);
}
