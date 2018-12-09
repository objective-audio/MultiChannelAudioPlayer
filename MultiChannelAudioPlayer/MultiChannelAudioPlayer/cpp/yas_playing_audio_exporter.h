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

    using export_proc_f = std::function<void(uint32_t const ch_idx, proc::time::range const &, audio::pcm_buffer &)>;
    using export_written_f = std::function<void(uint32_t const ch_idx, proc::time::range const &)>;
    using export_completion_f = std::function<void(export_result_t const &)>;

    enum class clear_error {
        remove_failed,
    };
    using clear_result_t = result<std::nullptr_t, clear_error>;

    audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                   operation_queue queue);
    audio_exporter(std::nullptr_t);

    void update_format(double const sample_rate, audio::pcm_format const, std::function<void(void)> completion_handler);

    void export_file(uint32_t const ch_idx, proc::time::range const &, export_proc_f, export_written_f,
                     export_completion_f);

    void clear(std::function<void(clear_result_t const &)> result_handler);

    [[nodiscard]] double sample_rate() const;
    [[nodiscard]] audio::pcm_format pcm_format() const;
};
}  // namespace yas::playing

namespace yas {
std::string to_string(playing::audio_exporter::export_error const &);
}
