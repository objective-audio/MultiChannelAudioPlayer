//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_audio_configulation.h"

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    audio_coordinator(std::string root_path);
    audio_coordinator(std::nullptr_t);

    void set_playing(bool const);
    void seek(int64_t const);
    void reload_all();
    void reload(proc::time::range const &);

    [[nodiscard]] double sample_rate() const;
    [[nodiscard]] audio::pcm_format pcm_format() const;
    [[nodiscard]] uint32_t channel_count() const;

    [[nodiscard]] chaining::chain_sync_t<audio_configuration> chain_configuration() const;
};
}  // namespace yas::playing
