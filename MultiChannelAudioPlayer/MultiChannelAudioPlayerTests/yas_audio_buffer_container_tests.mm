//
//  yas_audio_buffer_container_tests.mm
//

#import <XCTest/XCTest.h>
#import <audio/audio.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

namespace yas::playing::audio_buffer_container_test {
static audio::format make_format(double sample_rate) {
    return audio::format{audio::format::args{
        .sample_rate = sample_rate, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
}

static audio_buffer_container::ptr make_container(audio::format format, uint32_t const file_length) {
    audio::pcm_buffer container_buffer{format, file_length};
    return make_audio_buffer_container(std::move(container_buffer));
}

static audio_buffer_container::ptr make_container(uint32_t const file_length) {
    auto format = make_format(file_length);
    return make_container(format, file_length);
}
}

@interface yas_audio_buffer_container_tests : XCTestCase

@end

@implementation yas_audio_buffer_container_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_initial {
    uint32_t const file_length = 3;
    auto format = audio_buffer_container_test::make_format(file_length);
    auto const container = playing::audio_buffer_container_test::make_container(format, file_length);

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
    auto const container = audio_buffer_container_test::make_container(3);

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
    auto format = audio_buffer_container_test::make_format(file_length);
    auto container = audio_buffer_container_test::make_container(format, file_length);

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
    auto format = audio_buffer_container_test::make_format(file_length);
    auto container = audio_buffer_container_test::make_container(format, file_length);

    container->prepare_loading(0);

    auto load_result = container->load(0, [self](audio::pcm_buffer &buffer, int64_t const frag_idx) { return false; });

    XCTAssertFalse(load_result);
}

- (void)test_contains {
    uint32_t const file_length = 3;
    auto const container = audio_buffer_container_test::make_container(file_length);

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
