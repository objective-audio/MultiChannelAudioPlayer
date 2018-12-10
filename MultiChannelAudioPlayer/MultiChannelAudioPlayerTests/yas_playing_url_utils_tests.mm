//
//  yas_playing_url_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_playing_url_utils_tests : XCTestCase

@end

@implementation yas_playing_url_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_channel_url {
    auto root_url = url::file_url("/root");
    auto track_url = url_utils::channel_url(root_url, 1);

    XCTAssertEqual(track_url.path(), "/root/1");
}

- (void)test_caf_url_with_file_idx {
    auto ch_url = url_utils::channel_url(yas::url::file_url("/root"), 1);

    XCTAssertEqual(url_utils::caf_url(ch_url, 0).path(), "/root/1/0.caf");
    XCTAssertEqual(url_utils::caf_url(ch_url, 1).path(), "/root/1/1.caf");
    XCTAssertEqual(url_utils::caf_url(ch_url, -1).path(), "/root/1/-1.caf");
}

- (void)test_caf_idx {
    XCTAssertEqual(url_utils::caf_idx(0, 10), 0);
    XCTAssertEqual(url_utils::caf_idx(1, 10), 0);
    XCTAssertEqual(url_utils::caf_idx(9, 10), 0);
    XCTAssertEqual(url_utils::caf_idx(10, 10), 1);
    XCTAssertEqual(url_utils::caf_idx(-1, 10), -1);
    XCTAssertEqual(url_utils::caf_idx(-10, 10), -1);
    XCTAssertEqual(url_utils::caf_idx(-11, 10), -2);
}

@end
