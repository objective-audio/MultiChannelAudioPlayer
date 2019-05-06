//
//  yas_playing_timeline_utils.cpp
//

#include "yas_playing_timeline_utils.h"
#include <audio/yas_audio_format.h>
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

char const *timeline_utils::char_data(proc::signal_event const &event) {
    auto const &type = event.sample_type();

    if (type == typeid(double)) {
        return reinterpret_cast<char const *>(event.data<double>());
    } else if (type == typeid(float)) {
        return reinterpret_cast<char const *>(event.data<float>());
    } else if (type == typeid(int64_t)) {
        return reinterpret_cast<char const *>(event.data<int64_t>());
    } else if (type == typeid(uint64_t)) {
        return reinterpret_cast<char const *>(event.data<uint64_t>());
    } else if (type == typeid(int32_t)) {
        return reinterpret_cast<char const *>(event.data<int32_t>());
    } else if (type == typeid(uint32_t)) {
        return reinterpret_cast<char const *>(event.data<uint32_t>());
    } else if (type == typeid(int16_t)) {
        return reinterpret_cast<char const *>(event.data<int16_t>());
    } else if (type == typeid(uint16_t)) {
        return reinterpret_cast<char const *>(event.data<uint16_t>());
    } else if (type == typeid(int8_t)) {
        return reinterpret_cast<char const *>(event.data<int8_t>());
    } else if (type == typeid(uint8_t)) {
        return reinterpret_cast<char const *>(event.data<uint8_t>());
    } else if (type == typeid(boolean)) {
        return reinterpret_cast<char const *>(event.data<boolean>());
    } else {
        return nullptr;
    }
}

char *timeline_utils::char_data(audio::pcm_buffer &buffer) {
    switch (buffer.format().pcm_format()) {
        case audio::pcm_format::float32:
            return reinterpret_cast<char *>(buffer.data_ptr_at_index<float>(0));
        case audio::pcm_format::float64:
            return reinterpret_cast<char *>(buffer.data_ptr_at_index<double>(0));
        case audio::pcm_format::int16:
            return reinterpret_cast<char *>(buffer.data_ptr_at_index<int16_t>(0));
        case audio::pcm_format::fixed824:
            return reinterpret_cast<char *>(buffer.data_ptr_at_index<int32_t>(0));
        case audio::pcm_format::other:
            return nullptr;
    }
}
