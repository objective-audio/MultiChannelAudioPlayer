//
//  yas_multi_track_audio_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_file_manager.h"
#import "yas_multi_track_audio_exporter.h"
#import "yas_system_url.h"

#import <iostream>

using namespace yas;

@interface yas_multi_track_audio_exporter_tests : XCTestCase

@end

@implementation yas_multi_track_audio_exporter_tests

- (void)setUp {
    auto document_url = system_url::directory_url(system_url::dir::document);
    file_manager::remove_files_in_directory(document_url.path());
}

- (void)tearDown {
    auto document_url = system_url::directory_url(system_url::dir::document);
    file_manager::remove_files_in_directory(document_url.path());
}

- (void)test_export_file {
    auto document_url = system_url::directory_url(system_url::dir::document);
    std::cout << document_url << std::endl;
    double sample_rate = 48000;

    multi_track::audio_exporter exporter{sample_rate, audio::pcm_format::int16, document_url};

    XCTestExpectation *expectation = [self expectationWithDescription:@"export"];

    exporter.export_file(0, proc::time::range{0, static_cast<proc::length_t>(48001)},
                         [](audio::pcm_buffer &pcm_buffer, proc::time::range const &range) { NSLog(@"process"); },
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             if (!result) {
                                 std::cout << to_string(result.error()) << std::endl;
                             }
                             [expectation fulfill];
                         });

    [self waitForExpectations:@[expectation] timeout:10.0];

    {
        auto const exists_result = file_manager::file_exists(document_url.appending("0/0.caf").path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::file_kind::file);
    }

    {
        auto const exists_result = file_manager::file_exists(document_url.appending("0/1.caf").path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::file_kind::file);
    }
}

@end
