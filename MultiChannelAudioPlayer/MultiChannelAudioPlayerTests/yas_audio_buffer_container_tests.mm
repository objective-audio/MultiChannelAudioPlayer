//
//  yas_audio_buffer_container_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_audio_file_utils.h"
#import "yas_fast_each.h"
#import "yas_playing_audio_buffer_container.h"
#import "yas_playing_test_utils.h"
#import "yas_system_url_utils.h"
#import "yas_url.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_buffer_container_tests : XCTestCase

@end

@implementation yas_audio_buffer_container_tests

- (void)setUp {
    playing_test_utils::remove_all_document_files();
}

- (void)tearDown {
    playing_test_utils::remove_all_document_files();
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
    auto const doc_url = system_url_utils::directory_url(system_url_utils::dir::document);
    std::string const file_name = "test.caf";
    auto const file_url = doc_url.appending(file_name);

    auto file_result = audio::make_created_file(
        audio::file::create_args{.file_url = file_url.cf_url(),
                                 .file_type = audio::file_type::wave,
                                 .settings = audio::wave_file_settings(double(file_length), 1, 16),
                                 .pcm_format = audio::pcm_format::int16,
                                 .interleaved = false});

    if (file_result.is_error()) {
        throw std::runtime_error("make_created_file failed");
    }

    auto &file = file_result.value();

    audio::format format{audio::format::args{.sample_rate = double(file_length),
                                             .channel_count = 1,
                                             .pcm_format = audio::pcm_format::int16,
                                             .interleaved = false}};
    audio::pcm_buffer buffer{format, file_length};

    int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
    auto each = make_fast_each(file_length);
    while (yas_each_next(each)) {
        int16_t const &idx = yas_each_index(each);
        data_ptr[idx] = idx;
    }

    if (auto write_result = file.write_from_buffer(buffer); write_result.is_error()) {
        throw std::runtime_error("write_from_buffer failed");
    }

    return file;
}

@end
