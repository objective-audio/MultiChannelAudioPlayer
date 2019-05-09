//
//  yas_playing_audio_configulation.h
//

#pragma once

#include <processing/yas_processing_types.h>

namespace yas::playing {
struct audio_configuration {
    proc::sample_rate_t sample_rate;
    audio::pcm_format pcm_format = audio::pcm_format::float32;
    std::size_t channel_count;

    bool operator==(audio_configuration const &rhs) const {
        return this->sample_rate == rhs.sample_rate && this->pcm_format == rhs.pcm_format &&
               this->channel_count == rhs.channel_count;
    }

    bool operator!=(audio_configuration const &rhs) const {
        return !(*this == rhs);
    }
};
}  // namespace yas::playing
