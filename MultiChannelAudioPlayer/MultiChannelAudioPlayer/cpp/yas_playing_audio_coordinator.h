//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include "yas_audio_pcm_buffer.h"
#include "yas_base.h"
#include "yas_processing_time.h"

namespace yas {
class url;
}

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    using export_proc_f = std::function<void(uint32_t const ch_idx, audio::pcm_buffer &, proc::time::range const &)>;

    audio_coordinator(url root_url);
    audio_coordinator(std::nullptr_t);

    void set_export_proc_handler(export_proc_f);
    void export_file(uint32_t const ch_idx, proc::time::range const range);

    void set_playing(bool const);
    void seek(int64_t const);
};
}  // namespace yas::playing
