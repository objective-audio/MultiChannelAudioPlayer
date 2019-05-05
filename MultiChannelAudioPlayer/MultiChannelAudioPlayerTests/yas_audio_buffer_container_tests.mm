//
//  yas_audio_buffer_container_tests.mm
//

#import <XCTest/XCTest.h>
#import <audio/yas_audio_each_data.h>
#import <audio/yas_audio_file_utils.h>
#import <cpp_utils/yas_fast_each.h>
#import <cpp_utils/yas_system_path_utils.h>
#import <cpp_utils/yas_url.h>
#import <playing/yas_playing_audio_buffer_container.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

namespace yas::playing::test_utils {
audio::format make_format(double sample_rate) {
    return audio::format{audio::format::args{
        .sample_rate = sample_rate, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
}

audio_buffer_container::ptr make_container(audio::format format, uint32_t const file_length) {
    audio::pcm_buffer container_buffer{format, file_length};
    return make_audio_buffer_container(std::move(container_buffer));
}

audio_buffer_container::ptr make_container(uint32_t const file_length) {
    auto format = make_format(file_length);
    return make_container(format, file_length);
}

audio::file make_file(uint32_t const file_length) {
    auto const doc_url = system_path_utils::directory_url(system_path_utils::dir::document);
    std::string const file_name = "test.caf";
    auto const file_url = doc_url.appending(file_name);

    auto file_result = audio::make_created_file(
        audio::file::create_args{.file_url = file_url,
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

    auto each = audio::make_each_data<int16_t>(buffer);
    while (yas_each_data_next(each)) {
        yas_each_data_value(each) = yas_each_data_index(each);
    }

    if (auto write_result = file.write_from_buffer(buffer); write_result.is_error()) {
        throw std::runtime_error("write_from_buffer failed");
    }

    file.close();

    if (auto open_result = file.open(audio::file::open_args{
            .file_url = file_url,
            .pcm_format = audio::pcm_format::int16,
            .interleaved = false,
        });
        open_result.is_error()) {
        throw std::runtime_error("file open failed");
    }

    return file;
}
}

@interface yas_audio_buffer_container_tests : XCTestCase

@end

@implementation yas_audio_buffer_container_tests

- (void)setUp {
    test_utils::remove_all_document_files();
}

- (void)tearDown {
    test_utils::remove_all_document_files();
}

- (void)test_initial {
    uint32_t const file_length = 3;
    auto format = test_utils::make_format(file_length);
    auto const container = playing::test_utils::make_container(format, file_length);

    XCTAssertTrue(container);
    XCTAssertFalse(container->fragment_idx());
    XCTAssertFalse(container->begin_frame());
    XCTAssertEqual(container->format(), format);
    XCTAssertFalse(container->contains(0));

    audio::pcm_buffer reading_buffer{format, file_length};
    XCTAssertEqual(container->read_into_buffer(reading_buffer, 0).error(),
                   audio_buffer_container::read_error::unloaded);
}

- (void)test_prepare_loading {
    auto const container = test_utils::make_container(3);

    XCTAssertFalse(container->fragment_idx());

    container->prepare_loading(0);

    XCTAssertEqual(*container->fragment_idx(), 0);
    XCTAssertEqual(*container->begin_frame(), 0);

    container->prepare_loading(1);

    XCTAssertEqual(*container->fragment_idx(), 1);
    XCTAssertEqual(*container->begin_frame(), 3);

    container->prepare_loading(-1);

    XCTAssertEqual(*container->fragment_idx(), -1);
    XCTAssertEqual(*container->begin_frame(), -3);
}

- (void)test_load_and_read_into_buffer {
    uint32_t const file_length = 3;
    auto format = test_utils::make_format(file_length);
    auto container = test_utils::make_container(format, file_length);

    container->prepare_loading(0);

    auto load_result = container->load(0, [self](audio::pcm_buffer &buffer, int64_t const frag_idx) {
        XCTAssertEqual(frag_idx, 0);

        int16_t *data_ptr = buffer.data_ptr_at_index<int16_t>(0);
        data_ptr[0] = 10;
        data_ptr[1] = 11;
        data_ptr[2] = 12;

        return true;
    });

    XCTAssertTrue(load_result);

    audio::pcm_buffer reading_buffer{format, file_length};

    auto read_result = container->read_into_buffer(reading_buffer, 0);

    XCTAssertTrue(read_result);

    int16_t const *data_ptr = reading_buffer.data_ptr_at_index<int16_t>(0);

    XCTAssertEqual(data_ptr[0], 10);
    XCTAssertEqual(data_ptr[1], 11);
    XCTAssertEqual(data_ptr[2], 12);
}

- (void)test_load_error {
    uint32_t const file_length = 3;
    auto format = test_utils::make_format(file_length);
    auto container = test_utils::make_container(format, file_length);

    container->prepare_loading(0);

    auto load_result = container->load(0, [self](audio::pcm_buffer &buffer, int64_t const frag_idx) { return false; });

    XCTAssertFalse(load_result);
}

- (void)test_contains {
    uint32_t const file_length = 3;
    auto const container = test_utils::make_container(file_length);

    container->prepare_loading(0);
    container->load(0, [](audio::pcm_buffer &buffer, int64_t const frag_idx) { return true; });

    XCTAssertTrue(container->contains(0));
    XCTAssertTrue(container->contains(1));
    XCTAssertTrue(container->contains(2));

    XCTAssertFalse(container->contains(-1));
    XCTAssertFalse(container->contains(3));

    container->prepare_loading(1);
    auto result = container->load(1, [](audio::pcm_buffer &buffer, int64_t const frag_idx) { return true; });
    XCTAssertTrue(result);

    XCTAssertTrue(container->contains(3));
    XCTAssertTrue(container->contains(4));
    XCTAssertTrue(container->contains(5));

    XCTAssertFalse(container->contains(2));
    XCTAssertFalse(container->contains(6));
}

@end
