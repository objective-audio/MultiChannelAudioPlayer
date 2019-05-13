//
//  yas_playing_audio_player_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import <future>
#import "yas_playing_test_audio_renderer.h"
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

namespace yas::playing::audio_player_test {
struct cpp {
    std::string const root_path =
        file_path{system_path_utils::directory_path(system_path_utils::dir::document)}.appending("root").string();
    uint32_t const ch_count = 2;
    proc::sample_rate_t const sample_rate = 3;
    audio::format format = audio::format{audio::format::args{.sample_rate = static_cast<double>(this->sample_rate),
                                                             .channel_count = 2,
                                                             .pcm_format = audio::pcm_format::int16,
                                                             .interleaved = false}};
    task_queue queue{nullptr};
    timeline_exporter exporter{nullptr};
    test_utils::test_audio_renderer renderer{nullptr};
};
}

@interface yas_playing_audio_player_tests : XCTestCase

@end

@implementation yas_playing_audio_player_tests {
    audio_player_test::cpp _cpp;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_cpp.queue = task_queue{queue_priority_count};

    self->_cpp.exporter = timeline_exporter{self->_cpp.root_path, self->_cpp.queue, self->_cpp.sample_rate};

    self->_cpp.renderer = test_utils::test_audio_renderer{};
    self->_cpp.renderer.set_pcm_format(audio::pcm_format::int16);
    self->_cpp.renderer.set_sample_rate(self->_cpp.sample_rate);
    self->_cpp.renderer.set_channel_count(2);
}

- (void)tearDown {
    self->_cpp.queue.cancel_all();
    self->_cpp.queue.wait_until_all_tasks_are_finished();

    self->_cpp.queue = nullptr;
    self->_cpp.exporter = nullptr;
    self->_cpp.renderer = nullptr;

    test_utils::remove_all_document_files();
}

- (void)test_initial {
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    XCTAssertFalse(player.is_playing());
    XCTAssertEqual(player.play_frame(), 0);
    XCTAssertEqual(player.root_path(), self->_cpp.root_path);
}

- (void)test_is_playing {
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    XCTAssertFalse(player.is_playing());

    player.set_playing(true);

    XCTAssertTrue(player.is_playing());

    player.set_playing(false);

    XCTAssertFalse(player.is_playing());
}

- (void)test_seek_without_format {
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    XCTAssertEqual(player.play_frame(), 0);

    player.seek(1);

    XCTAssertEqual(player.play_frame(), 1);

    player.seek(10);

    XCTAssertEqual(player.play_frame(), 10);

    player.seek(-1);

    XCTAssertEqual(player.play_frame(), -1);
}

- (void)test_render {
    [self setup_files];

    audio_player player{self->_cpp.renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    uint32_t const render_length = 2;
    audio::pcm_buffer render_buffer{self->_cpp.format, render_length};
    int16_t const *data_ptr_0 = render_buffer.data_ptr_at_index<int16_t>(0);
    int16_t const *data_ptr_1 = render_buffer.data_ptr_at_index<int16_t>(1);

    player.set_playing(true);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 0);
    XCTAssertEqual(data_ptr_0[1], 1);
    XCTAssertEqual(data_ptr_1[0], 1000);
    XCTAssertEqual(data_ptr_1[1], 1001);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 2);
    XCTAssertEqual(data_ptr_0[1], 3);
    XCTAssertEqual(data_ptr_1[0], 1002);
    XCTAssertEqual(data_ptr_1[1], 1003);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 4);
    XCTAssertEqual(data_ptr_0[1], 5);
    XCTAssertEqual(data_ptr_1[0], 1004);
    XCTAssertEqual(data_ptr_1[1], 1005);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 6);
    XCTAssertEqual(data_ptr_0[1], 7);
    XCTAssertEqual(data_ptr_1[0], 1006);
    XCTAssertEqual(data_ptr_1[1], 1007);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 8);
    XCTAssertEqual(data_ptr_0[1], 9);
    XCTAssertEqual(data_ptr_1[0], 1008);
    XCTAssertEqual(data_ptr_1[1], 1009);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 10);
    XCTAssertEqual(data_ptr_0[1], 11);
    XCTAssertEqual(data_ptr_1[0], 1010);
    XCTAssertEqual(data_ptr_1[1], 1011);
}

- (void)test_seek {
    [self setup_files];

    audio_player player{self->_cpp.renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    uint32_t const render_length = 2;
    audio::pcm_buffer render_buffer{self->_cpp.format, render_length};
    int16_t const *data_ptr_0 = render_buffer.data_ptr_at_index<int16_t>(0);
    int16_t const *data_ptr_1 = render_buffer.data_ptr_at_index<int16_t>(1);

    player.set_playing(true);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 0);
    XCTAssertEqual(data_ptr_0[1], 1);
    XCTAssertEqual(data_ptr_1[0], 1000);
    XCTAssertEqual(data_ptr_1[1], 1001);

    render_buffer.clear();

    player.seek(6);

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 6);
    XCTAssertEqual(data_ptr_0[1], 7);
    XCTAssertEqual(data_ptr_1[0], 1006);
    XCTAssertEqual(data_ptr_1[1], 1007);
}

- (void)test_reload {
    [self setup_files];

    audio_player player{self->_cpp.renderer.renderable(), self->_cpp.root_path, self->_cpp.queue};

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    uint32_t const render_length = 2;
    audio::pcm_buffer render_buffer{self->_cpp.format, render_length};
    int16_t const *data_ptr_0 = render_buffer.data_ptr_at_index<int16_t>(0);
    int16_t const *data_ptr_1 = render_buffer.data_ptr_at_index<int16_t>(1);

    player.set_playing(true);

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 0);
    XCTAssertEqual(data_ptr_0[1], 1);
    XCTAssertEqual(data_ptr_1[0], 1000);
    XCTAssertEqual(data_ptr_1[1], 1001);

    render_buffer.clear();

    self->_cpp.exporter.set_timeline_container(
        {"0", self->_cpp.sample_rate, test_utils::test_timeline(100, self->_cpp.ch_count)});

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    player.reload(0, 0);
    player.reload(1, 0);

    self->_cpp.queue.wait_until_all_tasks_are_finished();

    [self render:render_buffer];

    XCTAssertEqual(data_ptr_0[0], 102);
    XCTAssertEqual(data_ptr_0[1], 3);
    XCTAssertEqual(data_ptr_1[0], 1102);
    XCTAssertEqual(data_ptr_1[1], 1003);
}

#pragma mark -

- (void)setup_files {
    self->_cpp.exporter.set_timeline_container(
        {"0", self->_cpp.sample_rate, test_utils::test_timeline(0, self->_cpp.ch_count)});
    self->_cpp.queue.wait_until_all_tasks_are_finished();
}

- (void)render:(audio::pcm_buffer &)render_buffer {
    render_buffer.clear();

    std::promise<void> promise;
    auto future = promise.get_future();

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_cpp.renderer, &render_buffer, &promise] {
                       renderer.render(render_buffer);

                       promise.set_value();
                   });

    future.get();

    self->_cpp.queue.wait_until_all_tasks_are_finished();
}

@end
