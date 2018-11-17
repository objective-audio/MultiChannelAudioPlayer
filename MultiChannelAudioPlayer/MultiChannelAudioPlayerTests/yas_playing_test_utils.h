//
//  yas_playing_test_utils.h
//

#pragma once

#include "yas_playing_audio_exporter.h"

namespace yas::playing::test_utils {
void remove_all_document_files();
void setup_files(audio_exporter &exporter, std::function<void(audio_exporter::export_result_t const &)> &&completion);
void overwrite_file(audio_exporter &exporter,
                    std::function<void(audio_exporter::export_result_t const &)> &&completion);
std::vector<audio::pcm_buffer> make_render_buffers(audio::format const &, uint32_t const buffer_count,
                                                   uint32_t const frame_length);
}  // namespace yas::playing::test_utils
