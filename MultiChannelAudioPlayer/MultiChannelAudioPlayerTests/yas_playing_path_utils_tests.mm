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

- (void)test_signal_file_name {
    XCTAssertEqual(path_utils::signal_file_name({0, 1}, typeid(double)), "signal_0_1_f64");
    XCTAssertEqual(path_utils::signal_file_name({-1, 2}, typeid(double)), "signal_-1_2_f64");
}

- (void)test_fragment_path {
    auto frag_path = path_utils::fragment_path("/root", 1, 2);

    XCTAssertEqual(frag_path, "/root/1/2");
}

- (void)test_signal_file_path {
    auto signal_path = path_utils::signal_file_path("/root", 1, 2, {10, 11}, typeid(int64_t));

    XCTAssertEqual(signal_path, "/root/1/2/signal_10_11_i64");
}

@end
