//
//  yas_audio_circuler_buffer_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_audio_format.h"
#import "yas_playing_audio_circular_buffer.h"
#import "yas_playing_audio_exporter.h"
#import "yas_playing_test_utils.h"
#import "yas_playing_url_utils.h"
#import "yas_system_url_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_circuler_buffer_tests : XCTestCase

@end

@implementation yas_audio_circuler_buffer_tests {
    double _sample_rate;
    uint32_t _file_length;
    int64_t _ch_idx;
    operation_queue _queue;
    std::shared_ptr<yas::url> _root_url;
    std::shared_ptr<audio::format> _format;
    std::shared_ptr<playing::audio_exporter> _exporter;
}

- (void)setUp {
    playing_test_utils::remove_all_document_files();

    self->_ch_idx = 0;

    auto const doc_url = system_url_utils::directory_url(system_url_utils::dir::document);
    self->_root_url = std::make_shared<yas::url>(doc_url.appending("root"));

    self->_sample_rate = 3;
    self->_file_length = 3;

    self->_format = std::make_shared<audio::format>(audio::format::args{.sample_rate = self->_sample_rate,
                                                                        .channel_count = 1,
                                                                        .pcm_format = audio::pcm_format::int16,
                                                                        .interleaved = false});

    self->_exporter =
        std::make_shared<playing::audio_exporter>(self->_sample_rate, audio::pcm_format::int16, *self->_root_url);
}

- (void)tearDown {
    playing_test_utils::remove_all_document_files();
}

- (void)test_read_into_buffer {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    [self setup_files_with_completion:[setup_exp](auto const &result) { [setup_exp fulfill]; }];
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    auto const ch_url = url_utils::channel_url(*self->_root_url, self->_ch_idx);
    audio_circular_buffer circular_buffer{*self->_format, 2, ch_url, self->_queue};

    circular_buffer.reload_all(-1);
    self->_queue.wait_until_all_operations_are_finished();

    audio::pcm_buffer read_buffer{*self->_format, 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer.read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer.rotate_buffer(0);
    self->_queue.wait_until_all_operations_are_finished();

    read_buffer.clear();

    circular_buffer.read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);
    XCTAssertEqual(data_ptr[2], 2);

    circular_buffer.rotate_buffer(1);
    self->_queue.wait_until_all_operations_are_finished();

    read_buffer.clear();

    circular_buffer.read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

- (void)test_reload {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    [self setup_files_with_completion:[setup_exp](auto const &result) { [setup_exp fulfill]; }];
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    auto const ch_url = url_utils::channel_url(*self->_root_url, self->_ch_idx);
    audio_circular_buffer circular_buffer{*self->_format, 3, ch_url, self->_queue};

    circular_buffer.reload_all(-1);
    self->_queue.wait_until_all_operations_are_finished();

    auto overwrite_exp = [self expectationWithDescription:@"overwrite"];
    [self overwrite_file_with_completion:[overwrite_exp](auto const &result) { [overwrite_exp fulfill]; }];
    [self waitForExpectations:@[overwrite_exp] timeout:10.0];

    circular_buffer.reload(0);
    self->_queue.wait_until_all_operations_are_finished();

    audio::pcm_buffer read_buffer{*self->_format, 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer.read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer.rotate_buffer(0);
    self->_queue.wait_until_all_operations_are_finished();

    read_buffer.clear();

    circular_buffer.read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 100);
    XCTAssertEqual(data_ptr[1], 101);
    XCTAssertEqual(data_ptr[2], 102);

    circular_buffer.rotate_buffer(1);
    self->_queue.wait_until_all_operations_are_finished();

    read_buffer.clear();

    circular_buffer.read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

#pragma mark -

- (void)setup_files_with_completion:(std::function<void(audio_exporter::export_result_t const &)> &&)completion {
    self->_exporter->export_file(0, proc::time::range{-3, 18},
                                 [](audio::pcm_buffer &pcm_buffer, proc::time::range const &range) {
                                     int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                                     auto each = make_fast_each(range.length);
                                     while (yas_each_next(each)) {
                                         auto const &idx = yas_each_index(each);
                                         data[idx] = int16_t(range.frame + idx);
                                     }
                                 },
                                 std::move(completion));
}

- (void)overwrite_file_with_completion:(std::function<void(audio_exporter::export_result_t const &)> &&)completion {
    self->_exporter->export_file(0, proc::time::range{0, 3},
                                 [](audio::pcm_buffer &pcm_buffer, proc::time::range const &range) {
                                     int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                                     auto each = make_fast_each(range.length);
                                     while (yas_each_next(each)) {
                                         auto const &idx = yas_each_index(each);
                                         data[idx] = int16_t(range.frame + idx + 100);
                                     }
                                 },
                                 std::move(completion));
}

@end
