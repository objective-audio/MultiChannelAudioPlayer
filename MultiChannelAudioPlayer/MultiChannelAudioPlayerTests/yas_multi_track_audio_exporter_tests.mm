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
    auto url = system_url::directory_url(system_url::dir::document);
}

@end
