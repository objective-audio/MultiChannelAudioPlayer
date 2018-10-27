//
//  yas_system_url_utils_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_system_url_utils.h"
#import "yas_url.h"

using namespace yas;

@interface yas_system_url_utils_tests : XCTestCase

@end

@implementation yas_system_url_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_document_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::document);
    std::string expected = "/Documents";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_caches_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::caches);
    std::string expected = "/Caches";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_temporary_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::temporary);
    std::string expected = "/tmp";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

@end
