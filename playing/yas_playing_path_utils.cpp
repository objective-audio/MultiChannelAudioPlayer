//
//  yas_playing_url.cpp
//

#include "yas_playing_path_utils.h"
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"
#include "yas_playing_signal_file_info.h"

using namespace yas;
using namespace yas::playing;

channel_path::channel_path(std::string const &root_path, channel_index_t const ch_idx)
    : root_path(root_path), channel_index(ch_idx) {
}

std::string channel_path::string() const {
    return file_path{this->root_path}.appending(path_utils::channel_name(this->channel_index)).string();
}

fragment_path::fragment_path(playing::channel_path const &ch_path, fragment_index_t const frag_idx)
    : channel_path(ch_path), fragment_index(frag_idx) {
}

std::string fragment_path::string() const {
    return file_path{this->channel_path.string()}.appending(path_utils::fragment_name(this->fragment_index)).string();
}

signal_event_path::signal_event_path(playing::fragment_path const &frag_path, proc::time::range const &range,
                                     std::type_info const &sample_type)
    : fragment_path(frag_path), range(range), sample_type(sample_type) {
}

std::string signal_event_path::string() const {
    return file_path{this->fragment_path.string()}
        .appending(to_signal_file_name(this->range, this->sample_type))
        .string();
}

number_events_path::number_events_path(playing::fragment_path const &frag_path) : fragment_path(frag_path) {
}

std::string number_events_path::string() const {
    return file_path{this->fragment_path.string()}.appending("numbers").string();
}

channel_path playing::make_channel_path(std::string const &root_path, channel_index_t const ch_idx) {
    return channel_path{root_path, ch_idx};
}

fragment_path playing::make_fragment_path(channel_path const &ch_path, fragment_index_t const frag_idx) {
    return fragment_path{ch_path, frag_idx};
}

signal_event_path playing::make_signal_event_path(fragment_path const &frag_path, proc::time::range const &range,
                                                  std::type_info const &sample_type) {
    return signal_event_path{frag_path, range, sample_type};
}
std::string path_utils::channel_name(channel_index_t const ch_idx) {
    return std::to_string(ch_idx);
}

std::string path_utils::fragment_name(fragment_index_t const frag_idx) {
    return std::to_string(frag_idx);
}
