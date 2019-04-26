//
//  yas_playing_audio_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import <audio/yas_audio_umbrella.h>
#import <cpp_utils/yas_file_manager.h>
#import <cpp_utils/yas_system_url_utils.h>
#import <playing/yas_playing_audio_exporter.h>
#import <playing/yas_playing_audio_types.h>
#import "yas_playing_test_utils.h"

using namespace yas;
using namespace yas::playing;

@interface yas_playing_audio_exporter_tests : XCTestCase

@end

@implementation yas_playing_audio_exporter_tests {
    operation_queue _queue;
}

- (void)setUp {
    test_utils::remove_all_document_files();

    self->_queue = operation_queue{audio_queue_priority_count};
}

- (void)tearDown {
    test_utils::remove_all_document_files();
}

- (void)test_export_file {
    auto root_url = system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
    double const sample_rate = 3;
    uint32_t const file_length = sample_rate;
    audio::format format{audio::format::args{
        .sample_rate = sample_rate, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};

    playing::audio_exporter exporter{sample_rate, audio::pcm_format::int16, root_url, self->_queue};

    XCTestExpectation *firstExp = [self expectationWithDescription:@"export_first"];

    std::vector<std::pair<uint32_t, int64_t>> written_params;

    exporter.export_file(0, proc::time::range{-1, static_cast<proc::length_t>(file_length + 2)},
                         [](uint32_t const, proc::time::range const &range, audio::pcm_buffer &pcm_buffer) {
                             int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                             auto each = make_fast_each(range.length);
                             while (yas_each_next(each)) {
                                 auto const &idx = yas_each_index(each);
                                 data[idx] = int16_t(range.frame + idx);
                             }
                         },
                         [&written_params](uint32_t const ch_idx, int64_t const &file_idx) {
                             written_params.emplace_back(ch_idx, file_idx);
                         },
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             [firstExp fulfill];
                         });

    [self waitForExpectations:@[firstExp] timeout:10.0];

    XCTAssertEqual(written_params.size(), 3);
    XCTAssertEqual(written_params.at(0).first, 0);
    XCTAssertEqual(written_params.at(0).second, -1);
    XCTAssertEqual(written_params.at(1).first, 0);
    XCTAssertEqual(written_params.at(1).second, 0);
    XCTAssertEqual(written_params.at(2).first, 0);
    XCTAssertEqual(written_params.at(2).second, 1);

    auto assert_file = [=](audio::format const &format, url const &url, std::vector<int16_t> const &expected) {
        uint32_t const expected_length = static_cast<uint32_t>(expected.size());

        auto file_result = audio::make_opened_file(audio::file::open_args{
            .file_url = url,
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
        auto url = root_url.appending("0/-1.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {0, 0, -1});
    }

    {
        auto url = root_url.appending("0/0.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {0, 1, 2});
    }

    {
        auto url = root_url.appending("0/1.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {3, 0, 0});
    }

    XCTestExpectation *secondExp = [self expectationWithDescription:@"export_second"];

    exporter.export_file(0, proc::time::range{1, 1},
                         [](uint32_t const, proc::time::range const &range, audio::pcm_buffer &pcm_buffer) {
                             int16_t *const data = pcm_buffer.data_ptr_at_index<int16_t>(0);
                             auto each = make_fast_each(range.length);
                             while (yas_each_next(each)) {
                                 data[yas_each_index(each)] = 100;
                             }
                         },
                         [](uint32_t const ch_idx, int64_t const file_idx) {},
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             [secondExp fulfill];
                         });

    [self waitForExpectations:@[secondExp] timeout:10.0];

    {
        auto url = root_url.appending("0/-1.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {0, 0, -1});
    }

    {
        auto url = root_url.appending("0/0.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {0, 100, 2});
    }

    {
        auto url = root_url.appending("0/1.caf");

        auto const exists_result = file_manager::content_exists(url.path());
        XCTAssertTrue(exists_result);
        XCTAssertEqual(exists_result.value(), file_manager::content_kind::file);

        assert_file(format, url, {3, 0, 0});
    }

    XCTestExpectation *clearExp = [self expectationWithDescription:@"clear"];

    exporter.clear([=](auto const &result) {
        XCTAssertTrue(result.is_success());
        [clearExp fulfill];
    });

    [self waitForExpectations:@[clearExp] timeout:10.0];

    XCTAssertFalse(file_manager::content_exists(root_url.path()));
}

- (void)test_update_format {
    auto root_url = system_url_utils::directory_url(system_url_utils::dir::document).appending("root");

    audio::format format{audio::format::args{
        .sample_rate = 3, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};

    playing::audio_exporter exporter{3, audio::pcm_format::int16, root_url, self->_queue};

    XCTestExpectation *firstExp = [self expectationWithDescription:@"export_first"];

    exporter.export_file(0, proc::time::range{0, 3},
                         [](uint32_t const, proc::time::range const &range, audio::pcm_buffer &pcm_buffer) {},
                         [](uint32_t const ch_idx, int64_t const) {},
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             [firstExp fulfill];
                         });

    [self waitForExpectations:@[firstExp] timeout:10.0];

    {
        auto url = root_url.appending("0/0.caf");

        auto file_result = audio::make_opened_file(audio::file::open_args{
            .file_url = url,
            .pcm_format = audio::pcm_format::int16,
            .interleaved = false,
        });

        XCTAssertTrue(file_result);

        auto const &file = file_result.value();

        XCTAssertEqual(file.file_length(), 3);

        XCTAssertFalse(file_manager::content_exists(root_url.appending("0/-1.caf").path()));
        XCTAssertFalse(file_manager::content_exists(root_url.appending("0/1.caf").path()));
    }

    XCTestExpectation *updateExp = [self expectationWithDescription:@"update_format"];

    exporter.update_format(4, audio::pcm_format::int16, [=] { [updateExp fulfill]; });

    [self waitForExpectations:@[updateExp] timeout:10.0];

    XCTAssertFalse(file_manager::content_exists(root_url.path()));

    XCTestExpectation *secondExp = [self expectationWithDescription:@"export_second"];

    exporter.export_file(0, proc::time::range{0, 4},
                         [](uint32_t const, proc::time::range const &range, audio::pcm_buffer &pcm_buffer) {},
                         [](uint32_t const ch_idx, int64_t const) {},
                         [=](auto const &result) {
                             XCTAssertTrue(result.is_success());
                             [secondExp fulfill];
                         });

    [self waitForExpectations:@[secondExp] timeout:10.0];

    {
        auto url = root_url.appending("0/0.caf");

        auto file_result = audio::make_opened_file(audio::file::open_args{
            .file_url = url,
            .pcm_format = audio::pcm_format::int16,
            .interleaved = false,
        });

        XCTAssertTrue(file_result);

        auto const &file = file_result.value();

        XCTAssertEqual(file.file_length(), 4);

        XCTAssertFalse(file_manager::content_exists(root_url.appending("0/-1.caf").path()));
        XCTAssertFalse(file_manager::content_exists(root_url.appending("0/1.caf").path()));
    }
}

@end
