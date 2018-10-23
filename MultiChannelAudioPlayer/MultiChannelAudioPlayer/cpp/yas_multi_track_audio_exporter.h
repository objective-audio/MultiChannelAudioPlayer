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

    enum class export_error {
        erase_file_failed,
        invalid_process_range,
        copy_buffer_failed,
        write_failed,
        create_file_failed,
    };

    using export_result_t = result<std::nullptr_t, export_error>;

    audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url);

    void export_file(uint32_t const trk_idx, proc::time::range const &,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> proc_handler,
                     std::function<void(export_result_t const &)> result_handler);
};
}  // namespace yas::multi_track

namespace yas {
std::string to_string(multi_track::audio_exporter::export_error const &);
}
