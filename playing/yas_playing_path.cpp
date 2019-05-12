//
//  yas_playing_url.cpp
//

#include "yas_playing_path.h"
#include <cpp_utils/yas_boolean.h>
#include "yas_playing_math.h"
#include "yas_playing_signal_file_info.h"

using namespace yas;
using namespace yas::playing;
using namespace yas::playing::path;

timeline::timeline(std::string const &root_path, std::string const identifier, proc::sample_rate_t const sample_rate)
    : root_path(root_path), identifier(identifier), sample_rate(sample_rate) {
}

std::string timeline::string() const {
    return file_path{this->root_path}.appending(timeline_name(this->identifier, this->sample_rate)).string();
}

channel::channel(timeline const &timeline_path, channel_index_t const ch_idx)
    : timeline_path(timeline_path), channel_index(ch_idx) {
}

std::string channel::string() const {
    return file_path{this->timeline_path.string()}.appending(channel_name(this->channel_index)).string();
}

fragment::fragment(path::channel const &ch_path, fragment_index_t const frag_idx)
    : channel_path(ch_path), fragment_index(frag_idx) {
}

std::string fragment::string() const {
    return file_path{this->channel_path.string()}.appending(fragment_name(this->fragment_index)).string();
}

signal_event::signal_event(path::fragment const &frag_path, proc::time::range const &range,
                           std::type_info const &sample_type)
    : fragment_path(frag_path), range(range), sample_type(sample_type) {
}

std::string signal_event::string() const {
    return file_path{this->fragment_path.string()}
        .appending(to_signal_file_name(this->range, this->sample_type))
        .string();
}

number_events::number_events(path::fragment const &frag_path) : fragment_path(frag_path) {
}

std::string number_events::string() const {
    return file_path{this->fragment_path.string()}.appending("numbers").string();
}

std::string path::timeline_name(std::string const &identifier, sample_rate_t const sr) {
    return identifier + "_" + std::to_string(sr);
}

std::string path::channel_name(channel_index_t const ch_idx) {
    return std::to_string(ch_idx);
}

std::string path::fragment_name(fragment_index_t const frag_idx) {
    return std::to_string(frag_idx);
}
