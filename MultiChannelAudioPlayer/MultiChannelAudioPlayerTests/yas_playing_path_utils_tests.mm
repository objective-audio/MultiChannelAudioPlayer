//
//  yas_playing_url_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/yas_playing_path_utils.h>

using namespace yas;
using namespace yas::playing;

@interface yas_playing_path_utils_tests : XCTestCase

@end

@implementation yas_playing_path_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_channel_name {
    XCTAssertEqual(path_utils::channel_name(0), "0");
    XCTAssertEqual(path_utils::channel_name(1), "1");
    XCTAssertEqual(path_utils::channel_name(1000), "1000");
    XCTAssertEqual(path_utils::channel_name(-1), "-1");
}

- (void)test_fragment_name {
    XCTAssertEqual(path_utils::fragment_name(0), "0");
    XCTAssertEqual(path_utils::fragment_name(1), "1");
    XCTAssertEqual(path_utils::fragment_name(1000), "1000");
    XCTAssertEqual(path_utils::fragment_name(-1), "-1");
}

#warning todo

@end
