//
//  yas_playing_test_utils.cpp
//

#include "yas_playing_test_utils.h"
#include "yas_fast_each.h"
#include "yas_file_manager.h"
#include "yas_system_url_utils.h"

using namespace yas;
using namespace yas::playing;

void test_utils::remove_all_document_files() {
    auto document_url = system_url_utils::directory_url(system_url_utils::dir::document);
    file_manager::remove_files_in_directory(document_url.path());
}

void test_utils::setup_files(audio_exporter &exporter, uint32_t const ch_count,
                             std::function<void(void)> &&completion) {
    auto remain = std::make_shared<uint32_t>(ch_count);

    auto each = make_fast_each(ch_count);
    while (yas_each_next(each)) {
        auto const &ch_idx = yas_each_index(each);
        exporter.export_file(ch_idx, proc::time::range{-3, 18},
                             [](uint32_t const ch_idx, audio::pcm_buffer &pcm_buffer, proc::time::range const &range) {
                                 int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                                 auto each = make_fast_each(range.length);
                                 while (yas_each_next(each)) {
                                     auto const &idx = yas_each_index(each);
                                     data[idx] = int16_t(range.frame + idx + 1000 * ch_idx);
                                 }
                             },
                             [](uint32_t const ch_idx, proc::time::range const &) {},
                             [completion, remain](auto const &) {
                                 *remain -= 1;
                                 if (*remain == 0) {
                                     completion();
                                 }
                             });
    }
}

void test_utils::overwrite_file(audio_exporter &exporter, uint32_t const ch_count,
                                std::function<void(void)> &&completion) {
    auto remain = std::make_shared<uint32_t>(ch_count);

    auto each = make_fast_each(ch_count);
    while (yas_each_next(each)) {
        auto const &ch_idx = yas_each_index(each);
        exporter.export_file(ch_idx, proc::time::range{0, 3},
                             [ch_idx](uint32_t const, audio::pcm_buffer &pcm_buffer, proc::time::range const &range) {
                                 int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                                 auto each = make_fast_each(range.length);
                                 while (yas_each_next(each)) {
                                     auto const &idx = yas_each_index(each);
                                     data[idx] = int16_t(range.frame + idx + 100 + 1000 * ch_idx);
                                 }
                             },
                             [](uint32_t const ch_idx, proc::time::range const &) {},
                             [completion, remain](auto const &) {
                                 *remain -= 1;
                                 if (*remain == 0) {
                                     completion();
                                 }
                             });
    }
}
