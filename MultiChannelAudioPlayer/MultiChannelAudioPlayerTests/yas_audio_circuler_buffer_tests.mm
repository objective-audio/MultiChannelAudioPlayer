//
//  yas_audio_circuler_buffer_tests.mm
//

#import <XCTest/XCTest.h>
#import <audio/audio.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/yas_playing_audio_buffer_container.h>
#import <playing/yas_playing_audio_circular_buffer.h>
#import <playing/yas_playing_types.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_circuler_buffer_tests : XCTestCase

@end

@implementation yas_audio_circuler_buffer_tests {
    task_queue _queue;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_queue = task_queue{queue_priority_count};
}

- (void)tearDown {
    test_utils::remove_all_document_files();
}

- (void)test_read_into_buffer {
    auto circular_buffer = make_audio_circular_buffer([self format], 2, self -> _queue,
                                                      [](audio::pcm_buffer &buffer, int64_t const frag_idx) {
                                                          int64_t const top_frame_idx = frag_idx * 3;
                                                          int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
                                                          data_ptr[0] = top_frame_idx;
                                                          data_ptr[1] = top_frame_idx + 1;
                                                          data_ptr[2] = top_frame_idx + 2;
                                                          return true;
                                                      });

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
    int64_t offset = 0;

    auto circular_buffer = make_audio_circular_buffer([self format], 3, self -> _queue,
                                                      [&offset](audio::pcm_buffer &buffer, int64_t const frag_idx) {
                                                          int64_t const top_frame_idx = frag_idx * 3 + offset;
                                                          int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
                                                          data_ptr[0] = top_frame_idx;
                                                          data_ptr[1] = top_frame_idx + 1;
                                                          data_ptr[2] = top_frame_idx + 2;
                                                          return true;
                                                      });

    circular_buffer->reload_all(-1);
    self->_queue.wait_until_all_tasks_are_finished();

    offset = 100;

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
