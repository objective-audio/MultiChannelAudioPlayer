//
//  yas_playing_audio_types.h
//

#pragma once

namespace yas::playing {
enum queue_priority : std::size_t {
    player = 0,
    exporter = 1,
};

std::size_t const audio_queue_priority_count = 2;

struct audio_configuration {
    double sample_rate;
    audio::pcm_format pcm_format = audio::pcm_format::float32;
    uint32_t channel_count;

    bool operator==(audio_configuration const &rhs) const {
        return this->sample_rate == rhs.sample_rate && this->pcm_format == rhs.pcm_format &&
               this->channel_count == rhs.channel_count;
    }

    bool operator!=(audio_configuration const &rhs) const {
        return !(*this == rhs);
    }
};
}  // namespace yas::playing
