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
    [self remove_document_files];
}

- (void)tearDown {
    [self remove_document_files];
}

- (void)test_export_file {
    auto document_url = system_url::directory_url(system_url::dir::document);
    std::cout << document_url << std::endl;
    double const sample_rate = 3;
    uint32_t const file_length = sample_rate;
    audio::format format{audio::format::args{
        .sample_rate = sample_rate, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};

    multi_track::audio_exporter exporter{sample_rate, audio::pcm_format::int16, document_url};

    XCTestExpectation *expectation = [self expectationWithDescription:@"export"];

    exporter.export_file(0, proc::time::range{-1, static_cast<proc::length_t>(file_length + 2)},
                         [](audio::pcm_buffer &pcm_buffer, proc::time::range const &range) {
                             int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                             auto each = make_fast_each(range.length);
                             while (yas_each_next(each)) {
                                 auto const &idx = yas_each_index(each);
                                 data[idx] = int16_t(range.frame + idx);
                             }
                         },
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             if (!result) {
                                 std::cout << to_string(result.error()) << std::endl;
                             }
                             [expectation fulfill];
                         });

    [self waitForExpectations:@[expectation] timeout:10.0];

    auto assert_file = [=](audio::format const &format, url const &url, std::vector<int16_t> const &expected) {
        uint32_t const expected_length = static_cast<uint32_t>(expected.size());

        auto file_result = audio::make_opened_file(audio::file::open_args{
            .file_url = url.cf_url(),
            .pcm_format = audio::pcm_format::int16,
            .interleaved = false,
        });

        auto &file = file_result.value();

        audio::pcm_buffer buffer{format, expected_length};

        auto read_result = file.read_into_buffer(buffer);

        XCTAssertTrue(read_result);
        XCTAssertEqual(buffer.frame_length(), expected_length);

        int16_t const *const data = buffer.data_ptr_at_index<int16_t>(0);
        auto each = make_fast_each(expected_length);
        while (yas_each_next(each)) {
            auto const &idx = yas_each_index(each);
            XCTAssertEqual(data[idx], expected[idx]);
        }
    };

    {
        auto url = document_url.appending("0/-1.caf");

        auto const exists_result = file_manager::file_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::file_kind::file);

        assert_file(format, url, {0, 0, -1});
    }

    {
        auto url = document_url.appending("0/0.caf");

        auto const exists_result = file_manager::file_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::file_kind::file);

        assert_file(format, url, {0, 1, 2});
    }

    {
        auto url = document_url.appending("0/1.caf");

        auto const exists_result = file_manager::file_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::file_kind::file);

        assert_file(format, url, {3, 0, 0});
    }
}

- (void)remove_document_files {
    auto document_url = system_url::directory_url(system_url::dir::document);
    file_manager::remove_files_in_directory(document_url.path());
}

@end
