//
//  yas_playing_signal_file_info.cpp
//

#include "yas_playing_signal_file_info.h"
#include <cpp_utils/yas_boolean.h>
#include <cpp_utils/yas_stl_utils.h>
#include <cpp_utils/yas_to_integer.h>
#include "yas_playing_path_utils.h"

using namespace yas;
using namespace yas::playing;

signal_file_info::signal_file_info(proc::time::range const &range, std::type_info const &sample_type)
    : range(range), sample_type(sample_type) {
}

std::string signal_file_info::file_name() const {
    return path_utils::signal_file_name(this->range, this->sample_type);
}

std::type_info const &playing::to_sample_type(std::string const &name) {
    if (name == "f64") {
        return typeid(Float64);
    } else if (name == "f32") {
        return typeid(Float32);
    } else if (name == "i64") {
        return typeid(int64_t);
    } else if (name == "u64") {
        return typeid(uint64_t);
    } else if (name == "i32") {
        return typeid(int32_t);
    } else if (name == "u32") {
        return typeid(uint32_t);
    } else if (name == "i16") {
        return typeid(int16_t);
    } else if (name == "u16") {
        return typeid(uint16_t);
    } else if (name == "i8") {
        return typeid(int8_t);
    } else if (name == "u8") {
        return typeid(uint8_t);
    } else if (name == "b") {
        return typeid(boolean);
    } else {
        return typeid(std::nullptr_t);
    }
}

std::optional<signal_file_info> playing::to_signal_file_info(std::string const &file_name) {
    std::vector<std::string> splited = split(file_name, '/');
    if (splited.size() != 4) {
        return std::nullopt;
    }

    if (splited.at(0) != "signal") {
        return std::nullopt;
    }

    std::type_info const &sample_type = to_sample_type(splited.at(3));

    if (sample_type == typeid(std::nullptr_t)) {
        return std::nullopt;
    }

    auto const frame = to_integer<proc::frame_index_t>(splited.at(1));
    auto const length = to_integer<proc::length_t>(splited.at(2));

    return signal_file_info{proc::time::range{frame, length}, sample_type};
}
