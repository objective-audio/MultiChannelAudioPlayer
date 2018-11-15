//
//  yas_playing_audio_player_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_playing_audio_player.h"
#import "yas_playing_test_audio_renderer.h"
#import "yas_system_url_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_playing_audio_player_tests : XCTestCase

@end

@implementation yas_playing_audio_player_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_initial {
    auto root_url = system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url};

    XCTAssertFalse(player.is_playing());
    XCTAssertEqual(player.play_frame(), 0);
    XCTAssertEqual(player.root_url(), root_url);
}

- (void)test_is_playing {
    auto root_url = system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
    test_utils::test_audio_renderer renderer{};
    audio_player player{renderer.renderable(), root_url};

    XCTAssertFalse(player.is_playing());

    player.set_playing(true);

    XCTAssertTrue(player.is_playing());

    player.set_playing(false);

    XCTAssertFalse(player.is_playing());
}

@end
