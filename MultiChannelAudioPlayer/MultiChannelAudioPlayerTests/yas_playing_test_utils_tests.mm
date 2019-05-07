//
//  yas_playing_test_utils_tests.mm
//

#import <XCTest/XCTest.h>
#import <playing/playing.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_playing_test_utils_tests : XCTestCase

@end

@implementation yas_playing_test_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_test_timeline {
    auto timeline = test_utils::test_timeline(0, 2);

    auto expectation = [self expectationWithDescription:@""];
    expectation.expectedFulfillmentCount = 5;

    timeline.process({-5, 25}, proc::sync_source{5, 5},
                     [&expectation, self](proc::time::range const &range, proc::stream const &stream, bool &stop) {
                         if (range == proc::time::range{-5, 5}) {
                             XCTAssertEqual(stream.channels().size(), 2);
                             if (auto const events = stream.channel(0).filtered_events<int16_t, proc::signal_event>();
                                 events.size() == 1) {
                                 auto const &event = *events.begin();
                                 XCTAssertEqual(event.first, (proc::time::range{-3, 3}));
                                 auto const *data_ptr = event.second.data<int16_t>();
                                 XCTAssertEqual(data_ptr[0], -3);
                                 XCTAssertEqual(data_ptr[1], -2);
                                 XCTAssertEqual(data_ptr[2], -1);
                             } else {
                                 XCTFail(@"");
                             }
                             if (auto const events = stream.channel(1).filtered_events<int16_t, proc::signal_event>();
                                 events.size() == 1) {
                                 auto const &event = *events.begin();
                                 XCTAssertEqual(event.first, (proc::time::range{-3, 3}));
                             } else {
                                 XCTFail(@"");
                             }
                         } else if (range == proc::time::range{0, 5}) {
                             XCTAssertEqual(stream.channels().size(), 2);
                         } else if (range == proc::time::range{5, 5}) {
                             XCTAssertEqual(stream.channels().size(), 2);
                         } else if (range == proc::time::range{10, 5}) {
                             XCTAssertEqual(stream.channels().size(), 2);
                         } else if (range == proc::time::range{15, 5}) {
                             XCTAssertEqual(stream.channels().size(), 0);
                         } else {
                             XCTFail(@"");
                         }

                         [expectation fulfill];
                     });

    [self waitForExpectations:@[expectation] timeout:10.0];
}

@end
