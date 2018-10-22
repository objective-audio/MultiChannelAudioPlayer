//
//  yas_system_url_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_system_url.h"
#import "yas_url.h"

#import <iostream>

using namespace yas;

@interface yas_system_url_tests : XCTestCase

@end

@implementation yas_system_url_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_document_url {
    auto url = system_url::directory_url(system_url::dir::document);
    std::string expected = "/Documents";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_caches_url {
    auto url = system_url::directory_url(system_url::dir::caches);
    std::string expected = "/Caches";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_temporary_url {
    auto url = system_url::directory_url(system_url::dir::temporary);
    std::string expected = "/tmp";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

@end
