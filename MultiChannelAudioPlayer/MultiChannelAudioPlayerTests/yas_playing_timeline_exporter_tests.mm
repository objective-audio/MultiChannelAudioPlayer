//
//  yas_playing_timeline_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import <processing/processing.h>

using namespace yas;
using namespace yas::playing;

struct yas_playing_timeline_exporter_test_cpp {
    url root_url = system_url_utils::directory_url(system_url_utils::dir::document).appending("root");
    operation_queue queue{queue_priority_count};
};

@interface yas_playing_timeline_exporter_tests : XCTestCase

@end

@implementation yas_playing_timeline_exporter_tests {
    yas_playing_timeline_exporter_test_cpp _cpp;
}

- (void)setUp {
}

- (void)tearDown {
    file_manager::remove_content(self->_cpp.root_url.path());
}

- (void)test_initial {
    url &root_url = self->_cpp.root_url;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_url, queue, sample_rate};

    queue.wait_until_all_operations_are_finished();

    XCTAssertFalse(file_manager::content_exists(root_url.path()));
}

- (void)test_set_timeline {
    url &root_url = self->_cpp.root_url;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_url, queue, sample_rate};

    queue.wait_until_all_operations_are_finished();

    auto module0 = proc::make_signal_module<int64_t>(10);
    module0.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    auto module1 = proc::make_number_module<int64_t>(11);
    module1.connect_output(proc::to_connector_index(proc::constant::output::value), 1);

    proc::track track0;
    track0.push_back_module(module0, {-2, 5});
    proc::track track1;
    track1.push_back_module(module1, {10, 1});

    proc::timeline timeline{{{0, track0}, {1, track1}}};

    exporter.set_timeline(timeline);

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(root_url.path()));

    XCTAssertFalse(file_manager::content_exists(url_utils::channel_url(root_url, -1).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::channel_url(root_url, 0).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::channel_url(root_url, 1).path()));
    XCTAssertFalse(file_manager::content_exists(url_utils::channel_url(root_url, 2).path()));

    XCTAssertFalse(file_manager::content_exists(url_utils::fragment_url(root_url, 0, -2).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::fragment_url(root_url, 0, -1).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::fragment_url(root_url, 0, 0).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::fragment_url(root_url, 0, 1).path()));
    XCTAssertFalse(file_manager::content_exists(url_utils::fragment_url(root_url, 0, 2).path()));

    XCTAssertFalse(file_manager::content_exists(url_utils::fragment_url(root_url, 1, 4).path()));
    XCTAssertTrue(file_manager::content_exists(url_utils::fragment_url(root_url, 1, 5).path()));
    XCTAssertFalse(file_manager::content_exists(url_utils::fragment_url(root_url, 1, 6).path()));

    XCTAssertTrue(
        file_manager::content_exists(url_utils::signal_file_url(root_url, 0, -1, {-2, 2}, typeid(int64_t)).path()));
    XCTAssertTrue(
        file_manager::content_exists(url_utils::signal_file_url(root_url, 0, 0, {0, 2}, typeid(int64_t)).path()));
    XCTAssertTrue(
        file_manager::content_exists(url_utils::signal_file_url(root_url, 0, 1, {2, 1}, typeid(int64_t)).path()));

    XCTAssertTrue(url_utils::number_file_url(root_url, 1, 5));
}

- (void)test_set_sample_rate {
}

@end
