//
//  yas_multi_track_audio_exporter.h
//

#pragma once

#include <string>
#include "yas_audio.h"
#include "yas_base.h"
#include "yas_processing.h"
#include "yas_url.h"

namespace yas::multi_track {
struct audio_exporter : base {
    class impl;

    audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url);

    void export_file(uint32_t const trk_idx, proc::time::range const &,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)>);
};
}  // namespace yas::multi_track
