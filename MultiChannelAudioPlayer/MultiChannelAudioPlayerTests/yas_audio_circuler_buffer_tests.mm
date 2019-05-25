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

namespace yas::playing::audio_circular_buffer_test {
struct cpp {
    task_queue queue{nullptr};
    sample_rate_t const sample_rate = 3;
    channel_index_t const ch_idx = 0;
    std::size_t const ch_count = 1;
    url const root_url = system_path_utils::directory_url(system_path_utils::dir::document).appending("root");
    audio::format const format{audio::format::args{.sample_rate = static_cast<double>(this->sample_rate),
                                                   .channel_count = 1,
                                                   .pcm_format = audio::pcm_format::int16,
                                                   .interleaved = false}};
};
}

@interface yas_audio_circuler_buffer_tests : XCTestCase

@end

@implementation yas_audio_circuler_buffer_tests {
    audio_circular_buffer_test::cpp _cpp;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_cpp.queue = task_queue{queue_priority_count};
}

- (void)tearDown {
    self->_cpp.queue = nullptr;

    test_utils::remove_all_document_files();
}

- (void)test_read_into_buffer {
    auto &cpp = self->_cpp;
    task_queue &queue = cpp.queue;

    auto circular_buffer =
        make_audio_circular_buffer(cpp.format, 2, queue, [](audio::pcm_buffer &buffer, int64_t const frag_idx) {
            int64_t const top_frame_idx = frag_idx * 3;
            int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
            data_ptr[0] = top_frame_idx;
            data_ptr[1] = top_frame_idx + 1;
            data_ptr[2] = top_frame_idx + 2;
            return true;
        });

    circular_buffer->reload_all(-1);
    queue.wait_until_all_tasks_are_finished();

    audio::pcm_buffer read_buffer{cpp.format, 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer->read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer->rotate_buffer(0);
    queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);
    XCTAssertEqual(data_ptr[2], 2);

    circular_buffer->rotate_buffer(1);
    queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

- (void)test_reload {
    auto &cpp = self->_cpp;
    task_queue &queue = cpp.queue;

    int64_t offset = 0;

    auto circular_buffer =
        make_audio_circular_buffer(cpp.format, 3, queue, [&offset](audio::pcm_buffer &buffer, int64_t const frag_idx) {
            int64_t const top_frame_idx = frag_idx * 3 + offset;
            int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
            data_ptr[0] = top_frame_idx;
            data_ptr[1] = top_frame_idx + 1;
            data_ptr[2] = top_frame_idx + 2;
            return true;
        });

    circular_buffer->reload_all(-1);
    queue.wait_until_all_tasks_are_finished();

    offset = 100;

    circular_buffer->reload(0);
    queue.wait_until_all_tasks_are_finished();

    audio::pcm_buffer read_buffer{cpp.format, 3};
    int16_t const *data_ptr = read_buffer.data_ptr_at_index<int16_t>(0);

    circular_buffer->read_into_buffer(read_buffer, -3);

    XCTAssertEqual(data_ptr[0], -3);
    XCTAssertEqual(data_ptr[1], -2);
    XCTAssertEqual(data_ptr[2], -1);

    circular_buffer->rotate_buffer(0);
    queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 0);

    XCTAssertEqual(data_ptr[0], 100);
    XCTAssertEqual(data_ptr[1], 101);
    XCTAssertEqual(data_ptr[2], 102);

    circular_buffer->rotate_buffer(1);
    queue.wait_until_all_tasks_are_finished();

    read_buffer.clear();

    circular_buffer->read_into_buffer(read_buffer, 3);

    XCTAssertEqual(data_ptr[0], 3);
    XCTAssertEqual(data_ptr[1], 4);
    XCTAssertEqual(data_ptr[2], 5);
}

- (void)test_states {
    auto &cpp = self->_cpp;
    task_queue &queue = cpp.queue;

    auto circular_buffer = make_audio_circular_buffer(
        cpp.format, 2, queue, [](audio::pcm_buffer &buffer, int64_t const frag_idx) { return true; });

    XCTAssertEqual(circular_buffer->states().size(), 0);

    circular_buffer->reload_all(-1);
    queue.wait_until_all_tasks_are_finished();
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];

    XCTAssertEqual(circular_buffer->states().size(), 2);
    XCTAssertEqual(circular_buffer->states().count(-1), 1);
    XCTAssertEqual(circular_buffer->states().count(0), 1);
}

@end
