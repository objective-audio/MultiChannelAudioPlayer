//
//  yas_playing_timline_exporter_chain_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_file_manager.h>
#import <cpp_utils/yas_system_path_utils.h>
#import <cpp_utils/yas_thread.h>
#import <playing/playing.h>
#import <processing/processing.h>
#import <future>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::timeline_exporter_chain_test {
struct cpp {
    std::string root_path = system_path_utils::directory_url(system_path_utils::dir::document).appending("root").path();
    task_queue queue{queue_priority_count};
};
}

@interface yas_playing_timeline_exporter_chain_tests : XCTestCase

@end

@implementation yas_playing_timeline_exporter_chain_tests {
    timeline_exporter_chain_test::cpp _cpp;
}

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_update_timeline {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_tasks_are_finished();

    std::vector<timeline_exporter::event> received;

    proc::timeline timeline;

    {
        auto expectation = [self expectationWithDescription:@"set timeline"];

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        exporter.set_timeline(timeline);

        [self waitForExpectations:@[expectation] timeout:10.0];
    }

    XCTAssertEqual(received.size(), 1);
    XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::reset);

    proc::track track;

    {
        auto expectation = [self expectationWithDescription:@"insert track"];
        expectation.expectedFulfillmentCount = 2;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        auto module1 = proc::make_number_module<int64_t>(100);
        module1.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
        track.push_back_module(module1, {0, 1});

        timeline.insert_track(0, track);

        [self waitForExpectations:@[expectation] timeout:10.0];
    }

    XCTAssertEqual(received.size(), 3);
    XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_began);
    XCTAssertEqual(received.at(1).range, (proc::time::range{0, 2}));
    XCTAssertEqual(received.at(2).result.value(), timeline_exporter::method::export_ended);
    XCTAssertEqual(received.at(2).range, (proc::time::range{0, 2}));

    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertTrue(file_manager::content_exists(root_path));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    //
    //    auto module2 = proc::make_number_module<Float64>(1.0);
    //    module2.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
    //    track.push_back_module(module2, {2, 1});
    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 1, 1)));\
//
    //    auto module3 = proc::make_number_module<Float64>(2.0);
    //    module3.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    //    track.push_back_module(module3, {0, 1});
    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    //
    //    track.erase_module(module3, {0, 1});
    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    //
    //    track.erase_module(module1, {0, 1});
    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    //    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));
    //
    //    timeline.erase_track(0);
    //
    //    queue.wait_until_all_tasks_are_finished();
    //
    //    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));
}

@end
