//
//  yas_playing_test_utils.h
//

#pragma once

#include <processing/yas_processing_timeline.h>

namespace yas::playing::test_utils {
void remove_all_document_files();
proc::timeline test_timeline();
// void setup_files(audio_exporter &exporter, uint32_t const ch_count, std::function<void(void)> &&completion);
// void overwrite_file(audio_exporter &exporter, uint32_t const ch_count, std::function<void(void)> &&completion);
}  // namespace yas::playing::test_utils
