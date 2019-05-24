//
//  yas_audio_circular_buffer_chain_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/yas_playing_audio_circular_buffer.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

namespace yas::playing::audio_circular_buffer_chain_test {
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

@interface yas_audio_circular_buffer_chain_tests : XCTestCase

@end

@implementation yas_audio_circular_buffer_chain_tests {
    audio_circular_buffer_chain_test::cpp _cpp;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_cpp.queue = task_queue{queue_priority_count};
}

- (void)tearDown {
    self->_cpp.queue = nullptr;

    test_utils::remove_all_document_files();
}

- (void)test_states_chain {
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

    chaining::observer_pool pool;

    playing::audio_circular_buffer::state_map_holder_t states;

    pool += circular_buffer->states_chain().send_to(states.receiver()).sync();

    XCTAssertEqual(states.size(), 0);

    std::vector<chaining::event> received;

    pool +=
        circular_buffer->states_chain().perform([&received](auto const &event) { received.push_back(event); }).sync();

    XCTAssertEqual(received.size(), 1);
    XCTAssertEqual(received.at(0).type(), chaining::event_type::fetched);

    circular_buffer->reload_all(-1);

    queue.wait_until_all_tasks_are_finished();

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0]];

    XCTAssertEqual(received.size(), 5);
    XCTAssertEqual(received.at(1).type(), chaining::event_type::erased);
    // 間の2つの順番は不定
    //    XCTAssertEqual(received.at(2).type(), chaining::event_type::erased);
    //    XCTAssertEqual(received.at(3).type(), chaining::event_type::inserted);
    XCTAssertEqual(received.at(4).type(), chaining::event_type::inserted);

    XCTAssertEqual(states.size(), 2);
    XCTAssertTrue(states.has_value(-1));
    XCTAssertTrue(states.has_value(0));
}

@end
