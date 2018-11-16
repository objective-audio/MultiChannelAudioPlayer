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
    operation_queue _queue;
    std::shared_ptr<audio_exporter> _exporter;
}

- (void)setUp {
    self->_queue = operation_queue{};
}

- (void)tearDown {
    self->_queue = nullptr;
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

    auto root_url = [self root_url];
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url, self->_queue};

    renderer.set_pcm_format(audio::pcm_format::int16);
    renderer.set_sample_rate(3);
    renderer.set_channel_count(2);

    self->_queue.wait_until_all_operations_are_finished();
}

#pragma mark -

- (url)root_url {
    return system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
}

@end
