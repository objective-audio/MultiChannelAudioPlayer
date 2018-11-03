//
//  yas_audio_buffer_container_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_audio_file_utils.h"
#import "yas_playing_audio_buffer_container.h"
#import "yas_system_url_utils.h"
#import "yas_url.h"

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
    auto format = [self make_format_with_sample_rate:file_length];
    auto const container = [self make_container_with_format:format file_length:file_length];

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
    auto const container = [self make_container_with_file_length:3];

    XCTAssertFalse(container->file_idx());

    container->prepare_loading(0);

    XCTAssertEqual(*container->file_idx(), 0);

    container->prepare_loading(1);

    XCTAssertEqual(*container->file_idx(), 1);
}

- (void)test_load_from_file {
    uint32_t const file_length = 3;
    auto container = [self make_container_with_file_length:file_length];

#warning todo
}

- (void)test_read_into_buffer {
#warning todo
}

#pragma mark -

- (audio::format)make_format_with_sample_rate:(double)sample_rate {
    return audio::format{audio::format::args{
        .sample_rate = sample_rate, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
}

- (audio_buffer_container::ptr)make_container_with_format:(audio::format)format
                                              file_length:(uint32_t const)file_length {
    audio::pcm_buffer container_buffer{format, file_length};
    return make_audio_buffer_container(std::move(container_buffer));
}

- (audio_buffer_container::ptr)make_container_with_file_length:(uint32_t const)file_length {
    auto format = [self make_format_with_sample_rate:file_length];
    return [self make_container_with_format:format file_length:file_length];
}

- (audio::file)make_file_with_length:(uint32_t const)file_length {
    system_url_utils::directory_url(system_url_utils::dir::document);
    /*
     CFURLRef file_url = nullptr;
     CFStringRef file_type = nullptr;
     CFDictionaryRef settings = nullptr;
     audio::pcm_format pcm_format = pcm_format::float32;
     bool interleaved = false;
     */
    auto created_file = audio::make_created_file(audio::file::create_args{.file_type = audio::file_type::wave}).value();

    return audio::make_opened_file(audio::file::open_args{}).value();
}

@end
