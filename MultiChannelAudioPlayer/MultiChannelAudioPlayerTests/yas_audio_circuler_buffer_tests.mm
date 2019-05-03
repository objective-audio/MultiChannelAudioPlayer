//
//  yas_audio_circuler_buffer_tests.mm
//

#import <XCTest/XCTest.h>
#import <audio/yas_audio_format.h>
#import <cpp_utils/yas_system_path_utils.h>
#import <playing/yas_playing_audio_circular_buffer.h>
#import <playing/yas_playing_audio_exporter.h>
#import <playing/yas_playing_path_utils.h>
#import <playing/yas_playing_types.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_circuler_buffer_tests : XCTestCase

@end

@implementation yas_audio_circuler_buffer_tests {
    task_queue _queue;
    std::shared_ptr<playing::audio_exporter> _exporter;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_queue = task_queue{queue_priority_count};

    self->_exporter = std::make_shared<playing::audio_exporter>([self sample_rate], audio::pcm_format::int16,
                                                                [self root_url], self -> _queue);
}

- (void)tearDown {
    self->_exporter = nullptr;

    test_utils::remove_all_document_files();
}

- (void)test_read_into_buffer {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    test_utils::setup_files(*self->_exporter, [self ch_count], [setup_exp] { [setup_exp fulfill]; });
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    auto const ch_url = path_utils::channel_url([self root_url], [self ch_idx]);
    auto circular_buffer = make_audio_circular_buffer([self format], 2, ch_url, self -> _queue);

    circular_buffer->reload_all(-1);
    self->_queue.wait_until_all_tasks_are_finished();

    audio::pcm_buffer read_buffer{[self format], 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer->read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer->rotate_buffer(0);
    self->_queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);
    XCTAssertEqual(data_ptr[2], 2);

    circular_buffer->rotate_buffer(1);
    self->_queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

- (void)test_reload {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    test_utils::setup_files(*self->_exporter, [self ch_count], [setup_exp] { [setup_exp fulfill]; });
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    auto const ch_url = path_utils::channel_url([self root_url], [self ch_idx]);
    auto circular_buffer = make_audio_circular_buffer([self format], 3, ch_url, self -> _queue);

    circular_buffer->reload_all(-1);
    self->_queue.wait_until_all_tasks_are_finished();

    auto overwrite_exp = [self expectationWithDescription:@"overwrite"];
    test_utils::overwrite_file(*self->_exporter, [self ch_count], [overwrite_exp] { [overwrite_exp fulfill]; });
    [self waitForExpectations:@[overwrite_exp] timeout:10.0];

    circular_buffer->reload(0);
    self->_queue.wait_until_all_tasks_are_finished();

    audio::pcm_buffer read_buffer{[self format], 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer->read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer->rotate_buffer(0);
    self->_queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 100);
    XCTAssertEqual(data_ptr[1], 101);
    XCTAssertEqual(data_ptr[2], 102);

    circular_buffer->rotate_buffer(1);
    self->_queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

#pragma mark -

- (double)sample_rate {
    return 3.0;
}

- (uint32_t)file_length {
    return uint32_t([self sample_rate]);
}

- (int64_t)ch_idx {
    return 0;
}

- (uint32_t)ch_count {
    return 1;
}

- (yas::url)root_url {
    return system_path_utils::directory_url(system_path_utils::dir::document).appending("root");
}

- (audio::format)format {
    return audio::format{audio::format::args{.sample_rate = [self sample_rate],
                                             .channel_count = 1,
                                             .pcm_format = audio::pcm_format::int16,
                                             .interleaved = false}};
}

@end
