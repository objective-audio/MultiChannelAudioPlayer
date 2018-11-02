//
//  yas_audio_buffer_container_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_playing_audio_buffer_container.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_buffer_container_tests : XCTestCase

@end

@implementation yas_audio_buffer_container_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_initial {
    uint32_t const file_length = 10;
    audio::format format{audio::format::args{
        .sample_rate = file_length, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
    audio::pcm_buffer buffer{format, file_length};
    auto const container = make_audio_buffer_container(std::move(buffer));

    XCTAssertTrue(container);
    XCTAssertFalse(container->file_idx());
    XCTAssertFalse(container->begin_frame());
    XCTAssertEqual(container->format(), format);
    XCTAssertFalse(container->contains(0));
}

@end
