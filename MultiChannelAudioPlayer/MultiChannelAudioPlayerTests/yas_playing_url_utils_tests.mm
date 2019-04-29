//
//  yas_playing_url_tests.mm
//

#import <XCTest/XCTest.h>
#import <playing/yas_playing_url_utils.h>

using namespace yas;
using namespace yas::playing;

@interface yas_playing_url_utils_tests : XCTestCase

@end

@implementation yas_playing_url_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_channel_name {
    XCTAssertEqual(url_utils::channel_name(0), "0");
    XCTAssertEqual(url_utils::channel_name(1), "1");
    XCTAssertEqual(url_utils::channel_name(1000), "1000");
    XCTAssertEqual(url_utils::channel_name(-1), "-1");
}

- (void)test_fragment_name {
    XCTAssertEqual(url_utils::fragment_name(0), "0");
    XCTAssertEqual(url_utils::fragment_name(1), "1");
    XCTAssertEqual(url_utils::fragment_name(1000), "1000");
    XCTAssertEqual(url_utils::fragment_name(-1), "-1");
}

- (void)test_sample_type_name {
    XCTAssertEqual(url_utils::sample_type_name(typeid(double)), "f64");
    XCTAssertEqual(url_utils::sample_type_name(typeid(float)), "f32");
    XCTAssertEqual(url_utils::sample_type_name(typeid(int64_t)), "i64");
    XCTAssertEqual(url_utils::sample_type_name(typeid(uint64_t)), "u64");
    XCTAssertEqual(url_utils::sample_type_name(typeid(int32_t)), "i32");
    XCTAssertEqual(url_utils::sample_type_name(typeid(uint32_t)), "u32");
    XCTAssertEqual(url_utils::sample_type_name(typeid(int16_t)), "i16");
    XCTAssertEqual(url_utils::sample_type_name(typeid(uint16_t)), "u16");
    XCTAssertEqual(url_utils::sample_type_name(typeid(int8_t)), "i8");
    XCTAssertEqual(url_utils::sample_type_name(typeid(uint8_t)), "u8");

    XCTAssertEqual(url_utils::sample_type_name(typeid(std::string)), "");
}

- (void)test_signal_file_name {
    XCTAssertEqual(url_utils::signal_file_name({0, 1}, typeid(double)), "signal_0_1_f64");
    XCTAssertEqual(url_utils::signal_file_name({-1, 2}, typeid(double)), "signal_-1_2_f64");
}

- (void)test_channel_url {
    auto root_url = url::file_url("/root");
    auto ch_url = url_utils::channel_url(root_url, 1);

    XCTAssertEqual(ch_url.path(), "/root/1");
}

- (void)test_fragment_url {
    auto root_url = url::file_url("/root");
    auto frg_url = url_utils::fragment_url(root_url, 1, 2);

    XCTAssertEqual(frg_url.path(), "/root/1/2");
}

- (void)test_signal_file_url {
    auto root_url = url::file_url("/root");
    auto signal_url = url_utils::signal_file_url(root_url, 1, 2, {10, 11}, typeid(int64_t));

    XCTAssertEqual(signal_url.path(), "/root/1/2/signal_10_11_i64");
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
