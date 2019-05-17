//
//  yas_playing_timline_exporter_chain_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/yas_playing_timeline_exporter.h>
#import <playing/yas_playing_types.h>
#import <processing/processing.h>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::timeline_exporter_chain_test {
struct cpp {
    std::string const root_path =
        system_path_utils::directory_url(system_path_utils::dir::document).appending("root").path();
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

- (void)test_chain {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;
    std::string const identifier = "0";

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_tasks_are_finished();

    proc::timeline timeline;

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"set timeline"];

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        exporter.set_timeline_container({identifier, sample_rate, timeline});

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 1);
        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::reset);
    }

    proc::track track;

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"insert track"];
        expectation.expectedFulfillmentCount = 2;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        auto module = proc::make_number_module<int64_t>(100);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
        track.push_back_module(module, {0, 1});

        timeline.insert_track(0, track);

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 2);
        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::export_began);
        XCTAssertEqual(received.at(0).range, (proc::time::range{0, 2}));
        XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(1).range, (proc::time::range{0, 2}));
    }

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"insert module same range"];
        expectation.expectedFulfillmentCount = 2;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        auto module = proc::make_number_module<int64_t>(200);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
        track.push_back_module(module, {0, 1});

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 2);

        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::export_began);
        XCTAssertEqual(received.at(0).range, (proc::time::range{0, 2}));
        XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(1).range, (proc::time::range{0, 2}));
    }

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"insert module diff range"];
        expectation.expectedFulfillmentCount = 3;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        auto module = proc::make_number_module<Float64>(1.0);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
        track.push_back_module(module, {2, 3});

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 3);

        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::export_began);
        XCTAssertEqual(received.at(0).range, (proc::time::range{2, 4}));
        XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(1).range, (proc::time::range{2, 2}));
        XCTAssertEqual(received.at(2).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(2).range, (proc::time::range{4, 2}));
    }

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"erase module"];
        expectation.expectedFulfillmentCount = 2;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        track.erase_modules_for_range({0, 1});

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 2);

        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::export_began);
        XCTAssertEqual(received.at(0).range, (proc::time::range{0, 2}));
        XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(1).range, (proc::time::range{0, 2}));
    }

    {
        std::vector<timeline_exporter::event> received;

        auto expectation = [self expectationWithDescription:@"erase track"];
        expectation.expectedFulfillmentCount = 3;

        auto observer = exporter.event_chain()
                            .perform([&received, &expectation](auto const &event) {
                                received.push_back(event);
                                [expectation fulfill];
                            })
                            .end();

        timeline.erase_track(0);

        [self waitForExpectations:@[expectation] timeout:10.0];

        XCTAssertEqual(received.size(), 3);

        XCTAssertEqual(received.at(0).result.value(), timeline_exporter::method::export_began);
        XCTAssertEqual(received.at(0).range, (proc::time::range{2, 4}));
        XCTAssertEqual(received.at(1).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(1).range, (proc::time::range{2, 2}));
        XCTAssertEqual(received.at(2).result.value(), timeline_exporter::method::export_ended);
        XCTAssertEqual(received.at(2).range, (proc::time::range{4, 2}));
    }
}

@end
