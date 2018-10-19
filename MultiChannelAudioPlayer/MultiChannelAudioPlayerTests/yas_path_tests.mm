//
//  yas_path_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_path.h"

using namespace yas;

@interface yas_path_tests : XCTestCase

@end

@implementation yas_path_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_make_path {
    auto path = yas::path{"test/dir"};

    XCTAssertEqual(path.str(), "test/dir");
}

- (void)test_make_path_last_slash {
    auto path = yas::path{"test/dir/"};

    XCTAssertEqual(path.str(), "test/dir");
}

- (void)test_append {
    auto path = yas::path{"test/dir"};
    auto appended = path.appending("file.ext");

    XCTAssertEqual(appended.str(), "test/dir/file.ext");
}

@end
