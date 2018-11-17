//
//  yas_playing_audio_player_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_playing_audio_player.h"
#import "yas_playing_test_audio_renderer.h"
#import "yas_playing_test_utils.h"
#import "yas_system_url_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_playing_audio_player_tests : XCTestCase

@end

@implementation yas_playing_audio_player_tests {
    double _sample_rate;
    operation_queue _queue;
    std::shared_ptr<audio_exporter> _exporter;
    test_utils::test_audio_renderer _renderer;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_queue = operation_queue{};

    self->_exporter = std::make_shared<playing::audio_exporter>([self sample_rate], audio::pcm_format::int16,
                                                                [self root_url], self -> _queue);

    self->_renderer = test_utils::test_audio_renderer{};
    self->_renderer.set_pcm_format(audio::pcm_format::int16);
    self->_renderer.set_sample_rate([self sample_rate]);
    self->_renderer.set_channel_count(2);
}

- (void)tearDown {
    self->_queue.cancel();
    self->_queue.wait_until_all_operations_are_finished();

    self->_queue = nullptr;
    self->_exporter = nullptr;
    self->_renderer = nullptr;

    test_utils::remove_all_document_files();
}

- (void)test_initial {
    auto root_url = [self root_url];
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url, self->_queue};

    XCTAssertFalse(player.is_playing());
    XCTAssertEqual(player.play_frame(), 0);
    XCTAssertEqual(player.root_url(), root_url);
}

- (void)test_is_playing {
    auto root_url = [self root_url];
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url, self->_queue};

    XCTAssertFalse(player.is_playing());

    player.set_playing(true);

    XCTAssertTrue(player.is_playing());

    player.set_playing(false);

    XCTAssertFalse(player.is_playing());
}

- (void)test_seek_without_format {
    auto root_url = [self root_url];
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url, self->_queue};

    XCTAssertEqual(player.play_frame(), 0);

    player.seek(1);

    XCTAssertEqual(player.play_frame(), 1);

    player.seek(10);

    XCTAssertEqual(player.play_frame(), 10);

    player.seek(-1);

    XCTAssertEqual(player.play_frame(), -1);
}

- (void)test_render {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    test_utils::setup_files(*self->_exporter, [setup_exp](auto const &result) { [setup_exp fulfill]; });
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    audio_player player{self->_renderer.renderable(), [self root_url], self -> _queue};

    self->_queue.wait_until_all_operations_are_finished();

    uint32_t const buffer_count = 2;
    uint32_t const render_length = 2;
    auto render_buffers = test_utils::make_render_buffers([self format], buffer_count, render_length);
    auto &render_buffer = render_buffers.at(0);
    int16_t const *data_ptr = render_buffer.data_ptr_at_index<int16_t>(0);

    player.set_playing(true);

    auto render_exp1 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp1] {
                       renderer.render(render_buffers);

                       [render_exp1 fulfill];
                   });

    [self waitForExpectations:@[render_exp1] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);

    render_buffer.clear();

    auto render_exp2 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp2] {
                       renderer.render(render_buffers);

                       [render_exp2 fulfill];
                   });

    [self waitForExpectations:@[render_exp2] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 2);
    XCTAssertEqual(data_ptr[1], 3);
}

- (void)test_seek {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    test_utils::setup_files(*self->_exporter, [setup_exp](auto const &result) { [setup_exp fulfill]; });
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    audio_player player{self->_renderer.renderable(), [self root_url], self -> _queue};

    self->_queue.wait_until_all_operations_are_finished();

    uint32_t const buffer_count = 2;
    uint32_t const render_length = 2;
    auto render_buffers = test_utils::make_render_buffers([self format], buffer_count, render_length);
    auto &render_buffer = render_buffers.at(0);
    int16_t const *data_ptr = render_buffer.data_ptr_at_index<int16_t>(0);

    player.set_playing(true);

    auto render_exp1 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp1] {
                       renderer.render(render_buffers);

                       [render_exp1 fulfill];
                   });

    [self waitForExpectations:@[render_exp1] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);

    render_buffer.clear();

    player.seek(6);

    self->_queue.wait_until_all_operations_are_finished();

    auto render_exp2 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp2] {
                       renderer.render(render_buffers);

                       [render_exp2 fulfill];
                   });

    [self waitForExpectations:@[render_exp2] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 6);
    XCTAssertEqual(data_ptr[1], 7);
}

- (void)test_reload {
    auto setup_exp = [self expectationWithDescription:@"setup"];
    test_utils::setup_files(*self->_exporter, [setup_exp](auto const &result) { [setup_exp fulfill]; });
    [self waitForExpectations:@[setup_exp] timeout:10.0];

    audio_player player{self->_renderer.renderable(), [self root_url], self -> _queue};

    self->_queue.wait_until_all_operations_are_finished();

    uint32_t const buffer_count = 2;
    uint32_t const render_length = 2;
    auto render_buffers = test_utils::make_render_buffers([self format], buffer_count, render_length);
    auto &render_buffer = render_buffers.at(0);
    int16_t const *data_ptr = render_buffer.data_ptr_at_index<int16_t>(0);

    player.set_playing(true);

    auto render_exp1 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp1] {
                       renderer.render(render_buffers);

                       [render_exp1 fulfill];
                   });

    [self waitForExpectations:@[render_exp1] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 0);
    XCTAssertEqual(data_ptr[1], 1);

    render_buffer.clear();

    auto overwrite_exp = [self expectationWithDescription:@"overwrite"];
    test_utils::overwrite_file(*self->_exporter, [&overwrite_exp](auto const &result) { [overwrite_exp fulfill]; });

    [self waitForExpectations:@[overwrite_exp] timeout:1.0];

    player.reload(0, 0);

    self->_queue.wait_until_all_operations_are_finished();

    auto render_exp2 = [self expectationWithDescription:@"render1"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   [&renderer = self->_renderer, &render_buffers, &render_exp2] {
                       renderer.render(render_buffers);

                       [render_exp2 fulfill];
                   });

    [self waitForExpectations:@[render_exp2] timeout:1.0];

    XCTAssertEqual(data_ptr[0], 102);
    XCTAssertEqual(data_ptr[1], 3);
}

#pragma mark -

- (double)sample_rate {
    return 3.0;
}

- (uint32_t)file_length {
    return uint32_t([self sample_rate]);
}

- (url)root_url {
    return system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
}

- (audio::format)format {
    return audio::format{audio::format::args{.sample_rate = [self sample_rate],
                                             .channel_count = 1,
                                             .pcm_format = audio::pcm_format::int16,
                                             .interleaved = false}};
}

@end
