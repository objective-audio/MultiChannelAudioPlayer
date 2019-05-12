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

- (void)test_channel {
    path::channel ch_path{"/root", 1};

    XCTAssertEqual(ch_path.root_path, "/root");
    XCTAssertEqual(ch_path.channel_index, 1);
    XCTAssertEqual(ch_path.string(), "/root/1");
}

- (void)test_fragment {
    path::fragment frag_path{path::channel{"/root", 1}, 2};

    XCTAssertEqual(frag_path.fragment_index, 2);
    XCTAssertEqual(frag_path.string(), "/root/1/2");
}

- (void)test_signal_event {
    path::signal_event signal_event_path{path::fragment{path::channel{"/root", 1}, 2}, {3, 4}, typeid(int64_t)};

    XCTAssertEqual(signal_event_path.range, (proc::time::range{3, 4}));
    XCTAssertTrue(signal_event_path.sample_type == typeid(int64_t));
    XCTAssertEqual(signal_event_path.string(), "/root/1/2/signal_3_4_i64");
}

- (void)test_number_events {
    path::number_events number_events_path{path::fragment{path::channel{"/root", 1}, 2}};

    XCTAssertEqual(number_events_path.string(), "/root/1/2/numbers");
}

- (void)test_channel_name {
    XCTAssertEqual(path::channel_name(0), "0");
    XCTAssertEqual(path::channel_name(1), "1");
    XCTAssertEqual(path::channel_name(1000), "1000");
    XCTAssertEqual(path::channel_name(-1), "-1");
}

- (void)test_fragment_name {
    XCTAssertEqual(path::fragment_name(0), "0");
    XCTAssertEqual(path::fragment_name(1), "1");
    XCTAssertEqual(path::fragment_name(1000), "1000");
    XCTAssertEqual(path::fragment_name(-1), "-1");
}

@end
