//
//  yas_playing_timeline_utils.cpp
//

#include "yas_playing_timeline_utils.h"
#include "yas_playing_math.h"

using namespace yas;
using namespace yas::playing;

proc::time::range timeline_utils::fragments_range(proc::time::range const &range,
                                                  proc::sample_rate_t const sample_rate) {
    auto const frame = math::floor_int(range.frame, sample_rate);
    auto const next_frame = math::ceil_int(range.next_frame(), sample_rate);
    return proc::time::range{frame, static_cast<proc::length_t>(next_frame - frame)};
}

audio::pcm_format timeline_utils::to_pcm_format(std::type_info const &type) {
    if (type == typeid(Float64)) {
        return audio::pcm_format::float64;
    } else if (type == typeid(Float32)) {
        return audio::pcm_format::float32;
    } else if (type == typeid(int16_t)) {
        return audio::pcm_format::int16;
    } else if (type == typeid(int32_t)) {
        return audio::pcm_format::fixed824;
    } else {
        return audio::pcm_format::other;
    }
}
