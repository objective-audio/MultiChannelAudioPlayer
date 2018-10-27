//
//  yas_playing_url_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_playing_url.h"

#import <iostream>

using namespace yas;
using namespace yas::playing;

@interface yas_playing_url_tests : XCTestCase

@end

@implementation yas_playing_url_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_track_url {
    auto root_url = url::file_url("/root");
    auto track_url = url_utils::channel_url(root_url, 1);

    XCTAssertEqual(track_url.path(), "/root/1");
}

- (void)test_file_url {
    auto track_url = url_utils::channel_url(yas::url::file_url("/root"), 1);

    XCTAssertEqual(url_utils::caf_url(track_url, 0, 10).path(), "/root/1/0.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, 1, 10).path(), "/root/1/0.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, 9, 10).path(), "/root/1/0.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, 10, 10).path(), "/root/1/1.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, -1, 10).path(), "/root/1/-1.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, -10, 10).path(), "/root/1/-1.caf");
    XCTAssertEqual(url_utils::caf_url(track_url, -11, 10).path(), "/root/1/-2.caf");
}

@end
