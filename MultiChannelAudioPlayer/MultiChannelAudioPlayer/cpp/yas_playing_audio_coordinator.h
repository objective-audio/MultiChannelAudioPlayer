//
//  yas_playing_audio_coordinator.h
//

#pragma once

#include "yas_base.h"
#include "yas_processing_time.h"

namespace yas {
class url;
}

namespace yas::playing {
struct audio_coordinator : base {
    class impl;

    audio_coordinator(url root_url);
    audio_coordinator(std::nullptr_t);

    struct load_range {
        int64_t const ch_idx;
        proc::time::range const range;
    };

    void set_playing(bool const);
    void seek(int64_t const);
};
}  // namespace yas::playing
