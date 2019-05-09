//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_audio_configulation.h"
#include "yas_playing_types.h"

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    audio_coordinator(std::string root_path);
    audio_coordinator(std::nullptr_t);

    void set_playing(bool const);
    void seek(frame_index_t const);
    void reload_all();
    void reload(proc::time::range const &);

    [[nodiscard]] proc::sample_rate_t sample_rate() const;
    [[nodiscard]] audio::pcm_format pcm_format() const;
    [[nodiscard]] std::size_t channel_count() const;

    [[nodiscard]] chaining::chain_sync_t<audio_configuration> configuration_chain() const;
};
}  // namespace yas::playing
