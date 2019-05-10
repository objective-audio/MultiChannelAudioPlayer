//
//  yas_playing_timeline_utils.cpp
//

#include "yas_playing_timeline_utils.h"
#include <audio/yas_audio_format.h>
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"
#include <fstream>

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

char const *timeline_utils::char_frame_data(proc::time::frame::type const &frame) {
    return reinterpret_cast<char const *>(&frame);
}

sample_store_type timeline_utils::to_sample_store_type(std::type_info const &type) {
    if (type == typeid(double)) {
        return sample_store_type::float64;
    } else if (type == typeid(float)) {
        return sample_store_type::float32;
    } else if (type == typeid(int64_t)) {
        return sample_store_type::int64;
    } else if (type == typeid(uint64_t)) {
        return sample_store_type::uint64;
    } else if (type == typeid(int32_t)) {
        return sample_store_type::int32;
    } else if (type == typeid(uint32_t)) {
        return sample_store_type::uint32;
    } else if (type == typeid(int16_t)) {
        return sample_store_type::int16;
    } else if (type == typeid(uint16_t)) {
        return sample_store_type::uint16;
    } else if (type == typeid(int8_t)) {
        return sample_store_type::int8;
    } else if (type == typeid(uint8_t)) {
        return sample_store_type::uint8;
    } else if (type == typeid(boolean)) {
        return sample_store_type::boolean;
    } else {
        return sample_store_type::unknown;
    }
}

char const *timeline_utils::char_sample_store_type_data(sample_store_type const &store_type) {
    return reinterpret_cast<char const *>(&store_type);
}

std::type_info const &timeline_utils::to_sample_type(sample_store_type const &store_type) {
    switch (store_type) {
        case sample_store_type::float64:
            return typeid(double);
        case sample_store_type::float32:
            return typeid(float);
        case sample_store_type::int64:
            return typeid(int64_t);
        case sample_store_type::uint64:
            return typeid(uint64_t);
        case sample_store_type::int32:
            return typeid(int32_t);
        case sample_store_type::uint32:
            return typeid(int32_t);
        case sample_store_type::int16:
            return typeid(int16_t);
        case sample_store_type::uint16:
            return typeid(uint16_t);
        case sample_store_type::int8:
            return typeid(int8_t);
        case sample_store_type::uint8:
            return typeid(uint8_t);
        case sample_store_type::boolean:
            return typeid(boolean);
        default:
            return typeid(std::nullptr_t);
    }
}

char const *timeline_utils::char_value_data(proc::number_event const &event) {
    auto const &type = event.sample_type();

    if (type == typeid(double)) {
        return reinterpret_cast<char const *>(&event.get<double>());
    } else if (type == typeid(float)) {
        return reinterpret_cast<char const *>(&event.get<float>());
    } else if (type == typeid(int64_t)) {
        return reinterpret_cast<char const *>(&event.get<int64_t>());
    } else if (type == typeid(uint64_t)) {
        return reinterpret_cast<char const *>(&event.get<uint64_t>());
    } else if (type == typeid(int32_t)) {
        return reinterpret_cast<char const *>(&event.get<int32_t>());
    } else if (type == typeid(uint32_t)) {
        return reinterpret_cast<char const *>(&event.get<uint32_t>());
    } else if (type == typeid(int16_t)) {
        return reinterpret_cast<char const *>(&event.get<int16_t>());
    } else if (type == typeid(uint16_t)) {
        return reinterpret_cast<char const *>(&event.get<uint16_t>());
    } else if (type == typeid(int8_t)) {
        return reinterpret_cast<char const *>(&event.get<int8_t>());
    } else if (type == typeid(uint8_t)) {
        return reinterpret_cast<char const *>(&event.get<uint8_t>());
    } else if (type == typeid(boolean)) {
        return reinterpret_cast<char const *>(&event.get<boolean>());
    } else {
        return nullptr;
    }
}

std::multimap<frame_index_t, proc::number_event> timeline_utils::read_number_events(std::string const &path) {
    std::multimap<frame_index_t, proc::number_event> events;
    
    auto stream = std::ifstream{path, std::ios_base::in | std::ios_base::binary};
    if (stream.fail()) {
        return events;
    }
    
    while (!stream.fail() && !stream.eof()) {
        proc::time::frame::type frame;
        stream.read((char *)&frame, sizeof(proc::time::frame::type));
        if (stream.fail() || stream.gcount() != sizeof(proc::time::frame::type)) {
            return events;
        }
        
        sample_store_type store_type;
        stream.read((char *)&store_type, sizeof(sample_store_type));
        if (stream.fail() || stream.gcount() != sizeof(sample_store_type)) {
            return events;
        }
        
        switch (store_type) {
            case sample_store_type::float64: {
                double value;
                stream.read((char *)&value, sizeof(double));
                if (stream.fail()) {
                    return events;
                }
                
            } break;
            case sample_store_type::float32: {
                float value;
                stream.read((char *)&value, sizeof(float));
            }break;
            case sample_store_type::int64: {
                int64_t value;
                stream.read((char *)&value, sizeof(int64_t));
            }break;
            case sample_store_type::uint64: {
                uint64_t value;
                stream.read((char *)&value, sizeof(uint64_t));
            }break;
            case sample_store_type::int32: {
                int32_t value;
                stream.read((char *)&value, sizeof(int32_t));
            }break;
            case sample_store_type::uint32: {
                uint32_t value;
                stream.read((char *)&value, sizeof(uint32_t));
            }break;
            case sample_store_type::int16:{
                int16_t value;
                stream.read((char *)&value, sizeof(int16_t));
            }break;
            case sample_store_type::uint16:{
                uint16_t value;
                stream.read((char *)&value, sizeof(uint16_t));
            }break;
            case sample_store_type::int8:{
                int8_t value;
                stream.read((char *)&value, sizeof(int8_t));
            }break;
            case sample_store_type::uint8:{
                uint8_t value;
                stream.read((char *)&value, sizeof(uint8_t));
            }break;
            case sample_store_type::boolean:{
                bool value;
                stream.read((char *)&value, sizeof(bool));
            }break;
                
            default:
                return events;
        }
        int64_t value;
        stream.read((char *)&value, sizeof(int64_t));
        XCTAssertEqual(stream.gcount(), sizeof(int64_t));
        XCTAssertEqual(value, 11);
    }
    
    return events;
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
