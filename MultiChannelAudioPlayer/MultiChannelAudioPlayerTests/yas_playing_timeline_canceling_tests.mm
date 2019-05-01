//
//  yas_playing_timeline_canceling_tests.mm
//

#import <XCTest/XCTest.h>
#import <playing/yas_playing_timeline_canceling.h>

using namespace yas;

@interface yas_playing_timeline_canceling_tests : XCTestCase

@end

@implementation yas_playing_timeline_canceling_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_range_cancel_request {
    playing::timeline_cancel_matcher matcher{{1, 2}};
    playing::timeline_range_cancel_request range_request_a{{1, 2}};
    playing::timeline_range_cancel_request range_request_b{{0, 3}};
    playing::timeline_range_cancel_request range_request_c{{1, 3}};

    XCTAssertEqual(matcher, range_request_a);
    XCTAssertEqual(matcher, range_request_b);
    XCTAssertEqual(matcher, range_request_c);
    XCTAssertEqual(range_request_a, matcher);
    XCTAssertEqual(range_request_b, matcher);
    XCTAssertEqual(range_request_c, matcher);

    playing::timeline_range_cancel_request range_request_d{{1, 1}};
    playing::timeline_range_cancel_request range_request_e{{2, 1}};
    playing::timeline_range_cancel_request range_request_f{{0, 2}};
    playing::timeline_range_cancel_request range_request_g{{2, 2}};

    XCTAssertNotEqual(matcher, range_request_d);
    XCTAssertNotEqual(matcher, range_request_e);
    XCTAssertNotEqual(matcher, range_request_f);
    XCTAssertNotEqual(matcher, range_request_g);
    XCTAssertNotEqual(range_request_d, matcher);
    XCTAssertNotEqual(range_request_e, matcher);
    XCTAssertNotEqual(range_request_f, matcher);
    XCTAssertNotEqual(range_request_g, matcher);
}

@end
