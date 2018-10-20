//
//  yas_math_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_math.h"

using namespace yas;

@interface yas_math_tests : XCTestCase

@end

@implementation yas_math_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_floor_int {
    XCTAssertEqual(math::floor_int(0, 10), 0);
    XCTAssertEqual(math::floor_int(1, 10), 0);
    XCTAssertEqual(math::floor_int(9, 10), 0);
    XCTAssertEqual(math::floor_int(10, 10), 10);
    XCTAssertEqual(math::floor_int(11, 10), 10);
    XCTAssertEqual(math::floor_int(-1, 10), -10);
    XCTAssertEqual(math::floor_int(-9, 10), -10);
    XCTAssertEqual(math::floor_int(-10, 10), -10);
    XCTAssertEqual(math::floor_int(-11, 10), -20);
}

@end