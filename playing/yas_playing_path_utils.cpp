//
//  yas_playing_url.cpp
//

#include "yas_playing_path_utils.h"
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"
#include "yas_playing_signal_file_info.h"

using namespace yas::playing;

std::string path_utils::channel_name(int64_t const ch_idx) {
    return std::to_string(ch_idx);
}

std::string path_utils::fragment_name(int64_t const frag_idx) {
    return std::to_string(frag_idx);
}

std::string path_utils::channel_path(std::string const &root_path, int64_t const ch_idx) {
    return file_path{root_path}.appending(channel_name(ch_idx)).string();
}

std::string path_utils::fragment_path(std::string const &channel_path, int64_t const frag_idx) {
    return file_path{channel_path}.appending(fragment_name(frag_idx)).string();
}

std::string path_utils::signal_file_path(std::string const &fragment_path, proc::time::range const &range,
                                         std::type_info const &type_info) {
    return file_path{fragment_path}.appending(signal_file_info(range, type_info).file_name()).string();
}

std::string path_utils::number_file_path(std::string const &fragment_path) {
    return file_path{fragment_path}.appending("number").string();
}

std::string path_utils::fragment_path(std::string const &root_path, int64_t const ch_idx, int64_t const frag_idx) {
    return file_path{channel_path(root_path, ch_idx)}.appending(fragment_name(frag_idx)).string();
}

std::string path_utils::signal_file_path(std::string const &root_path, int64_t const ch_idx, int64_t const frag_idx,
                                         proc::time::range const &range, std::type_info const &type_info) {
    return file_path{fragment_path(root_path, ch_idx, frag_idx)}
        .appending(signal_file_info(range, type_info).file_name())
        .string();
}

std::string path_utils::number_file_path(std::string const &root_path, int64_t const ch_idx, int64_t const frag_idx) {
    return file_path{fragment_path(root_path, ch_idx, frag_idx)}.appending("number").string();
}
