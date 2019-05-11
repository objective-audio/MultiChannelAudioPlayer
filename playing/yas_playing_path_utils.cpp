//
//  yas_playing_url.cpp
//

#include "yas_playing_path_utils.h"
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"
#include "yas_playing_signal_file_info.h"

using namespace yas::playing;

std::string channel_path::string() const {
    return file_path{this->root_path}.appending(path_utils::channel_name(this->channel_index)).string();
}

std::string fragment_path::string() const {
    return file_path{this->channel_path.string()}.appending(path_utils::fragment_name(this->fragment_index)).string();
}

std::string signal_file_path::string() const {
    return file_path{this->fragment_path.string()}
        .appending(to_signal_file_name(this->range, this->sample_type))
        .string();
}

std::string number_file_path::string() const {
    return file_path{this->fragment_path.string()}.appending("number").string();
}

std::string path_utils::channel_name(channel_index_t const ch_idx) {
    return std::to_string(ch_idx);
}

std::string path_utils::fragment_name(fragment_index_t const frag_idx) {
    return std::to_string(frag_idx);
}

std::string path_utils::signal_file_path(std::string const &root_path, channel_index_t const ch_idx,
                                         fragment_index_t const frag_idx, proc::time::range const &range,
                                         std::type_info const &type_info) {
    channel_path const ch_path{.root_path = root_path, .channel_index = ch_idx};
    fragment_path const frag_path{.channel_path = ch_path, .fragment_index = frag_idx};
    return file_path{frag_path.string()}.appending(to_signal_file_name(range, type_info)).string();
}

std::string path_utils::number_file_path(std::string const &root_path, channel_index_t const ch_idx,
                                         fragment_index_t const frag_idx) {
    channel_path const ch_path{.root_path = root_path, .channel_index = ch_idx};
    fragment_path const frag_path{.channel_path = ch_path, .fragment_index = frag_idx};
    return file_path{frag_path.string()}.appending("number").string();
}
