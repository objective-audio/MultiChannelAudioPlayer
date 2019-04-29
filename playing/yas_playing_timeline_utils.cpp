//
//  yas_playing_timeline_utils.cpp
//

#include "yas_playing_timeline_utils.h"
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"

using namespace yas;
using namespace yas::playing;

proc::time::range timeline_utils::fragments_range(proc::time::range const &range,
                                                  proc::sample_rate_t const sample_rate) {
    auto const frame = math::floor_int(range.frame, sample_rate);
    auto const next_frame = math::ceil_int(range.next_frame(), sample_rate);
    return proc::time::range{frame, static_cast<proc::length_t>(next_frame - frame)};
}

std::string timeline_utils::to_string(proc::number_event const &event) {
    auto const &type = event.sample_type();

    if (type == typeid(double)) {
        return std::to_string(event.get<double>());
    } else if (type == typeid(float)) {
        return std::to_string(event.get<float>());
    } else if (type == typeid(int64_t)) {
        return std::to_string(event.get<int64_t>());
    } else if (type == typeid(uint64_t)) {
        return std::to_string(event.get<uint64_t>());
    } else if (type == typeid(int32_t)) {
        return std::to_string(event.get<int32_t>());
    } else if (type == typeid(uint32_t)) {
        return std::to_string(event.get<uint32_t>());
    } else if (type == typeid(int16_t)) {
        return std::to_string(event.get<int16_t>());
    } else if (type == typeid(uint16_t)) {
        return std::to_string(event.get<uint16_t>());
    } else if (type == typeid(int8_t)) {
        return std::to_string(event.get<int8_t>());
    } else if (type == typeid(uint8_t)) {
        return std::to_string(event.get<uint8_t>());
    } else if (type == typeid(boolean)) {
        return to_string(event.get<boolean>());
    } else {
        return "";
    }
}
