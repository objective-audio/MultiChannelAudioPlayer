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
                     [&expectation](proc::time::range const &range, proc::stream const &stream, bool &stop) {
                         [expectation fulfill];
                     });

    [self waitForExpectations:@[expectation] timeout:10.0];
}

@end
