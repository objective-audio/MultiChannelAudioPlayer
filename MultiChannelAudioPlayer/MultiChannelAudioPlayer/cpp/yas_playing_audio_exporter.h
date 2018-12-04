//
//  yas_playing_audio_exporter.h
//

#pragma once

#include <string>
#include "yas_audio_format.h"
#include "yas_audio_pcm_buffer.h"
#include "yas_base.h"
#include "yas_operation.h"
#include "yas_processing.h"
#include "yas_result.h"
#include "yas_url.h"

namespace yas::playing {
struct audio_exporter : base {
    class impl;

    enum class export_error {
        create_dir_failed,
        erase_file_failed,
        invalid_process_range,
        copy_buffer_failed,
        write_failed,
        create_file_failed,
    };
    using export_result_t = result<std::nullptr_t, export_error>;

    enum class clear_error {
        remove_failed,
    };
    using clear_result_t = result<std::nullptr_t, clear_error>;

    audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                   operation_queue queue);
    audio_exporter(std::nullptr_t);

    void update_format(double const sample_rate, audio::pcm_format const);

    void export_file(uint32_t const ch_idx, proc::time::range const &,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> proc_handler,
                     std::function<void(export_result_t const &)> result_handler);

    void clear(std::function<void(clear_result_t const &)> result_handler);

    double sample_rate() const;
    audio::pcm_format pcm_format() const;
};
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::audio_exporter::export_error const &);
}
