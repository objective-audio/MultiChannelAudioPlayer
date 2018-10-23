//
//  yas_multi_track_audio_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_multi_track_audio_exporter.h"
#import "yas_system_url.h"

using namespace yas;

@interface yas_multi_track_audio_exporter_tests : XCTestCase

@end

@implementation yas_multi_track_audio_exporter_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_export_file {
    auto document_url = system_url::directory_url(system_url::dir::document);
    double sample_rate = 48000;

    multi_track::audio_exporter exporter{sample_rate, audio::pcm_format::float32, document_url};

    XCTestExpectation *expectation = [self expectationWithDescription:@"export"];

    proc::time::range range{0, static_cast<proc::length_t>(48000)};

    exporter.export_file(0, range, [](auto &pcm_buffer, auto const &range) { NSLog(@"process"); },
                         [&expectation](auto const &result) {
                             NSLog(@"result");
                             [expectation fulfill];
                         });

    [self waitForExpectations:@[expectation] timeout:10.0];
}

@end
