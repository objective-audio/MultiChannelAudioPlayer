//
//  yas_system_url_utils_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_system_url_utils.h"
#import "yas_url.h"

#import <iostream>

using namespace yas;

@interface yas_system_url_utils_tests : XCTestCase

@end

@implementation yas_system_url_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_application_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::application);
    std::string expected = "/Applications";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_demo_application_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::demo_application);
    std::string expected = "/Applications/Demos";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_admin_application_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::admin_application);
    std::string expected = "/Applications/Utilities";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_library_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::library);
    std::string expected = "/Library";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_developer_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::developer);
    std::string expected = "/Developer";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
/*
- (void)test_user_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::user);
    std::string expected = "/";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
*/
- (void)test_documentation_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::documentation);
    std::string expected = "/Library/Documentation";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_document_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::document);
    std::string expected = "/Documents";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
/*
- (void)test_core_service_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::core_service);
    std::string expected = "/";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
*/
- (void)test_autosaved_information_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::autosaved_information);
    std::string expected = "/Library/Autosave Information";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_desktop_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::desktop);
    std::string expected = "/Desktop";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_caches_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::caches);
    std::string expected = "/Caches";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_application_support_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::application_support);
    std::string expected = "/Library/Application Support";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_downloads_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::downloads);
    std::string expected = "/Downloads";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_input_methods_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::input_methods);
    std::string expected = "/Library/Input Methods";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_movies_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::movies);
    std::string expected = "/Movies";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_music_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::music);
    std::string expected = "/Music";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_pictures_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::pictures);
    std::string expected = "/Pictures";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
/*
- (void)test_printer_description_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::printer_description);
    std::string expected = "/";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
*/
- (void)test_shared_public_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::shared_public);
    std::string expected = "/Public";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_preference_panes_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::preference_panes);
    std::string expected = "/Library/PreferencePanes";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
/*
#if (TARGET_OS_MAC && !TARGET_OS_IPHONE)

- (void)test_application_scripts_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::application_scripts);
    std::string expected = "/";
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

#endif

- (void)test_item_replacement_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::item_replacement);
    std::string expected = "/";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
*/
- (void)test_all_applications_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::all_applications);
    std::string expected = "/Applications";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_all_libraries_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::all_libraries);
    std::string expected = "/Library";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}

- (void)test_temporary_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::temporary);
    std::string expected = "/tmp";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
/*
- (void)test_home_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::home);
    std::string expected = "/";
    std::cout << url.path() << std::endl;
    XCTAssertEqual(url.path().compare(url.path().size() - expected.size(), expected.size(), expected), 0);
}
*/
- (void)test_open_step_root_url {
    auto url = system_url_utils::directory_url(system_url_utils::dir::open_step_root);
    std::string expected = "/";
    XCTAssertEqual(url.path(), expected);
}

@end
