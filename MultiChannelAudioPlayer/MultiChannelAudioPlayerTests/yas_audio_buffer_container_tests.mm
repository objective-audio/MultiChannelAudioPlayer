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
    uint32_t const file_length = 3;
    audio::format format{audio::format::args{
        .sample_rate = file_length, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
    audio::pcm_buffer container_buffer{format, file_length};
    auto const container = make_audio_buffer_container(std::move(container_buffer));

    XCTAssertTrue(container);
    XCTAssertFalse(container->file_idx());
    XCTAssertFalse(container->begin_frame());
    XCTAssertEqual(container->format(), format);
    XCTAssertFalse(container->contains(0));

    audio::pcm_buffer reading_buffer{format, file_length};
    XCTAssertEqual(container->read_into_buffer(reading_buffer, 0, 0, 1).error(),
                   audio_buffer_container::read_error::unloaded);
}

- (void)test_prepare_loading {
    uint32_t const file_length = 3;
    audio::format format{audio::format::args{
        .sample_rate = file_length, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
    audio::pcm_buffer container_buffer{format, file_length};
    auto const container = make_audio_buffer_container(std::move(container_buffer));

    XCTAssertFalse(container->file_idx());

    container->prepare_loading(0);

    XCTAssertEqual(*container->file_idx(), 0);

    container->prepare_loading(1);

    XCTAssertEqual(*container->file_idx(), 1);
}

- (void)test_load_from_file {
#warning todo
}

- (void)test_read_into_buffer {
#warning todo
}

@end
