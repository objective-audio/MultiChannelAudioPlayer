//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_base.h>
#include <processing/yas_processing_time.h>
#include "yas_playing_audio_types.h"

namespace yas {
class url;
}

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    using export_proc_f = std::function<void(uint32_t const ch_idx, proc::time::range const &, audio::pcm_buffer &)>;

    audio_coordinator(url root_url);
    audio_coordinator(std::nullptr_t);

    void set_export_proc_handler(export_proc_f);
    void export_file(uint32_t const ch_idx, proc::time::range const range);

    void set_playing(bool const);
    void seek(int64_t const);

    [[nodiscard]] double sample_rate() const;
    [[nodiscard]] audio::pcm_format pcm_format() const;
    [[nodiscard]] uint32_t channel_count() const;

    [[nodiscard]] chaining::chain_sync_t<audio_configuration> chain_configuration() const;
};
}  // namespace yas::playing
