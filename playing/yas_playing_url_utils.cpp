//
//  yas_playing_url.cpp
//

#include "yas_playing_url_utils.h"
#include "yas_playing_math.h"

using namespace yas::playing;

std::string url_utils::channel_name(int64_t const ch_idx) {
    return std::to_string(ch_idx);
}

std::string url_utils::fragment_name(int64_t const frg_idx) {
    return std::to_string(frg_idx);
}

std::string url_utils::sample_type_name(std::type_info const &type_info) {
    if (type_info == typeid(Float64)) {
        return "f64";
    } else if (type_info == typeid(Float32)) {
        return "f32";
    } else if (type_info == typeid(int64_t)) {
        return "i64";
    } else if (type_info == typeid(uint64_t)) {
        return "u64";
    } else if (type_info == typeid(int32_t)) {
        return "i32";
    } else if (type_info == typeid(uint32_t)) {
        return "u32";
    } else if (type_info == typeid(int16_t)) {
        return "i16";
    } else if (type_info == typeid(uint16_t)) {
        return "u16";
    } else if (type_info == typeid(int8_t)) {
        return "i8";
    } else if (type_info == typeid(uint8_t)) {
        return "u8";
    } else {
        return "";
    }
}

std::string url_utils::signal_file_name(proc::time::range const &range, std::type_info const &type_info) {
    return std::to_string(range.frame) + "_" + std::to_string(range.length) + "_" + sample_type_name(type_info) +
           ".signal";
}

yas::url url_utils::channel_url(yas::url const &root_url, int64_t const ch_idx) {
    return root_url.appending(channel_name(ch_idx));
}

yas::url url_utils::fragment_url(yas::url const &root_url, int64_t const ch_idx, int64_t const frg_idx) {
    return channel_url(root_url, ch_idx).appending(fragment_name(frg_idx));
}

yas::url url_utils::file_url(yas::url const &root_url, int64_t const ch_idx, int64_t const frg_idx,
                             proc::time::range const &range, std::type_info const &type_info) {
    return fragment_url(root_url, ch_idx, frg_idx).appending(signal_file_name(range, type_info));
}

yas::url url_utils::caf_url(yas::url const &ch_url, int64_t const file_idx) {
    return ch_url.appending(std::to_string(file_idx) + ".caf");
}

int64_t url_utils::caf_idx(int64_t const file_frame_idx, uint64_t const file_length) {
    int64_t const floored_frame_idx = math::floor_int(file_frame_idx, file_length);
    return floored_frame_idx / (int64_t)file_length;
}
