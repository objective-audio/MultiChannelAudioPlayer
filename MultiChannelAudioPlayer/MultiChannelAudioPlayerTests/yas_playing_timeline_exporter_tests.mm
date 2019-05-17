//
//  yas_playing_timeline_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import <playing/yas_playing_numbers_file.h>
#import <playing/yas_playing_signal_file.h>
#import <processing/processing.h>
#import <fstream>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::timeline_exporter_test {
struct cpp {
    std::string const root_path =
        system_path_utils::directory_url(system_path_utils::dir::document).appending("root").path();
    task_queue queue{queue_priority_count};
};
}

@interface yas_playing_timeline_exporter_tests : XCTestCase

@end

@implementation yas_playing_timeline_exporter_tests {
    timeline_exporter_test::cpp _cpp;
}

- (void)setUp {
    file_manager::remove_content(self->_cpp.root_path);
}

- (void)tearDown {
    self->_cpp.queue.cancel_all();
    self->_cpp.queue.wait_until_all_tasks_are_finished();
    file_manager::remove_content(self->_cpp.root_path);
}

- (void)test_initial {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_tasks_are_finished();

    XCTAssertFalse(file_manager::content_exists(root_path));
}

- (void)test_set_timeline {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;
    std::string const identifier = "0";
    path::timeline const tl_path{root_path, identifier, sample_rate};

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_tasks_are_finished();

    auto module0 = proc::make_signal_module<int64_t>(10);
    module0.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    auto module1 = proc::make_number_module<int64_t>(11);
    module1.connect_output(proc::to_connector_index(proc::constant::output::value), 1);

    proc::track track0;
    track0.push_back_module(module0, {-2, 5});
    proc::track track1;
    track1.push_back_module(module1, {10, 1});

    proc::timeline timeline{{{0, track0}, {1, track1}}};

    exporter.set_timeline_container({identifier, sample_rate, timeline});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertTrue(file_manager::content_exists(root_path));

    XCTAssertFalse(file_manager::content_exists(path::channel{tl_path, -1}.string()));
    XCTAssertTrue(file_manager::content_exists(path::channel{tl_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(path::channel{tl_path, 1}.string()));
    XCTAssertFalse(file_manager::content_exists(path::channel{tl_path, 2}.string()));

    auto const ch0_path = path::channel{tl_path, 0};

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch0_path, -2}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, -1}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 1}.string()));
    XCTAssertFalse(file_manager::content_exists(path::fragment{ch0_path, 2}.string()));

    auto const ch1_path = path::channel{tl_path, 1};

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch1_path, 4}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch1_path, 5}.string()));
    XCTAssertFalse(file_manager::content_exists(path::fragment{ch1_path, 6}.string()));

    XCTAssertTrue(file_manager::content_exists(
        path::signal_event{path::fragment{ch0_path, -1}, {-2, 2}, typeid(int64_t)}.string()));
    XCTAssertTrue(file_manager::content_exists(
        path::signal_event{path::fragment{ch0_path, 0}, {0, 2}, typeid(int64_t)}.string()));
    XCTAssertTrue(file_manager::content_exists(
        path::signal_event{path::fragment{ch0_path, 1}, {2, 1}, typeid(int64_t)}.string()));

    XCTAssertTrue(file_manager::content_exists(path::number_events{path::fragment{ch1_path, 5}}.string()));

    int64_t values[2];

    values[0] = values[1] = 0;

    {
        auto signal_path_str = path::signal_event{path::fragment{ch0_path, -1}, {-2, 2}, typeid(int64_t)}.string();
        auto result = playing::signal_file::read(signal_path_str, &values, sizeof(values));
        XCTAssertTrue(result);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
    }

    values[0] = values[1] = 0;

    {
        auto signal_path_str = path::signal_event{path::fragment{ch0_path, 0}, {0, 2}, typeid(int64_t)}.string();
        auto result = playing::signal_file::read(signal_path_str, &values, sizeof(values));
        XCTAssertTrue(result);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
    }

    values[0] = values[1] = 0;

    {
        auto signal_path_str = path::signal_event{path::fragment{ch0_path, 1}, {2, 1}, typeid(int64_t)}.string();
        auto result = playing::signal_file::read(signal_path_str, &values, sizeof(int64_t));
        XCTAssertTrue(result);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 0);
    }

    {
        auto result = playing::numbers_file::read(path::number_events{path::fragment{ch1_path, 5}}.string());
        XCTAssertTrue(result);
        auto const &event_pairs = result.value();
        XCTAssertEqual(event_pairs.size(), 1);
        auto const &event_pair = *event_pairs.begin();
        XCTAssertEqual(event_pair.first, 10);
        XCTAssertEqual(event_pair.second.get<int64_t>(), 11);
    }
}

- (void)test_set_sample_rate {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const pre_sample_rate = 2;
    proc::sample_rate_t const post_sample_rate = 3;
    std::string const identifier = "0";
    path::timeline const tl_path{root_path, identifier, post_sample_rate};

    timeline_exporter exporter{root_path, queue, pre_sample_rate};

    queue.wait_until_all_tasks_are_finished();

    auto module0 = proc::make_signal_module<int64_t>(10);
    module0.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    auto module1 = proc::make_number_module<int64_t>(11);
    module1.connect_output(proc::to_connector_index(proc::constant::output::value), 1);

    proc::track track0;
    track0.push_back_module(module0, {-2, 5});
    proc::track track1;
    track1.push_back_module(module1, {10, 1});

    proc::timeline timeline{{{0, track0}, {1, track1}}};

    exporter.set_timeline_container({identifier, pre_sample_rate, timeline});

    queue.wait_until_all_tasks_are_finished();

    exporter.set_timeline_container({identifier, post_sample_rate, timeline});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertTrue(file_manager::content_exists(root_path));

    XCTAssertFalse(file_manager::content_exists(path::channel{tl_path, -1}.string()));
    XCTAssertTrue(file_manager::content_exists(path::channel{tl_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(path::channel{tl_path, 1}.string()));
    XCTAssertFalse(file_manager::content_exists(path::channel{tl_path, 2}.string()));

    auto const ch0_path = path::channel{tl_path, 0};

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch0_path, -2}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, -1}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    XCTAssertFalse(file_manager::content_exists(path::fragment{ch0_path, 1}.string()));

    auto const ch1_path = path::channel{tl_path, 1};

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch1_path, 2}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch1_path, 3}.string()));
    XCTAssertFalse(file_manager::content_exists(path::fragment{ch1_path, 4}.string()));

    XCTAssertTrue(file_manager::content_exists(
        path::signal_event{path::fragment{ch0_path, -1}, {-2, 2}, typeid(int64_t)}.string()));
    XCTAssertTrue(file_manager::content_exists(
        path::signal_event{path::fragment{ch0_path, 0}, {0, 3}, typeid(int64_t)}.string()));

    auto const numbers_1_3_path_str = path::number_events{path::fragment{ch1_path, 3}}.string();

    XCTAssertTrue(file_manager::content_exists(numbers_1_3_path_str));

    int64_t values[3];

    values[0] = values[1] = values[2] = 0;

    {
        auto signal_path_str = path::signal_event{path::fragment{ch0_path, -1}, {-2, 2}, typeid(int64_t)}.string();
        auto result = playing::signal_file::read(signal_path_str, &values, sizeof(int64_t) * 2);
        XCTAssertTrue(result);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        XCTAssertEqual(values[2], 0);
    }

    values[0] = values[1] = values[2] = 0;

    {
        auto signal_path_str = path::signal_event{path::fragment{ch0_path, 0}, {0, 3}, typeid(int64_t)}.string();
        auto result = playing::signal_file::read(signal_path_str, &values, sizeof(values));
        XCTAssertTrue(result);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        XCTAssertEqual(values[2], 10);
    }

    values[0] = values[1] = values[2] = 0;

    {
        auto result = playing::numbers_file::read(numbers_1_3_path_str);
        XCTAssertTrue(result);
        auto const &event_pairs = result.value();
        XCTAssertEqual(event_pairs.size(), 1);
        auto const &event_pair = *event_pairs.begin();
        XCTAssertEqual(event_pair.first, 10);
        XCTAssertEqual(event_pair.second.get<int64_t>(), 11);
    }
}

- (void)test_update_timeline {
    std::string const &root_path = self->_cpp.root_path;
    task_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;
    std::string const identifier = "0";
    path::timeline const tl_path{root_path, identifier, sample_rate};

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_tasks_are_finished();

    proc::timeline timeline;

    exporter.set_timeline_container({identifier, sample_rate, timeline});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertFalse(file_manager::content_exists(root_path));

    proc::track track;
    auto module1 = proc::make_number_module<int64_t>(100);
    module1.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    track.push_back_module(module1, {0, 1});

    timeline.insert_track(0, track);

    queue.wait_until_all_tasks_are_finished();

    path::channel const ch0_path{tl_path, 0};

    XCTAssertTrue(file_manager::content_exists(root_path));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    auto const frag_0_0_path_str = path::number_events{path::fragment{ch0_path, 0}}.string();
    XCTAssertTrue(file_manager::content_exists(frag_0_0_path_str));
    if (auto result = playing::numbers_file::read(frag_0_0_path_str)) {
        XCTAssertEqual(result.value().size(), 1);
        XCTAssertEqual(result.value().begin()->first, 0);
        XCTAssertEqual(result.value().begin()->second.get<int64_t>(), 100);
    } else {
        XCTAssert(0);
    }

    auto module2 = proc::make_number_module<Float64>(1.0);
    module2.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
    track.push_back_module(module2, {2, 1});

    queue.wait_until_all_tasks_are_finished();

    path::channel const ch1_path{tl_path, 1};

    XCTAssertTrue(file_manager::content_exists(path::fragment{ch1_path, 1}.string()));
    auto const frag_1_1_path_str = path::number_events{path::fragment{ch1_path, 1}}.string();
    XCTAssertTrue(file_manager::content_exists(frag_1_1_path_str));
    if (auto result = playing::numbers_file::read(frag_1_1_path_str)) {
        XCTAssertEqual(result.value().size(), 1);
        XCTAssertEqual(result.value().begin()->first, 2);
        XCTAssertEqual(result.value().begin()->second.get<Float64>(), 1.0);
    } else {
        XCTAssert(0);
    }

    auto module3 = proc::make_number_module<boolean>(true);
    module3.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    track.push_back_module(module3, {0, 1});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(frag_0_0_path_str));
    if (auto result = playing::numbers_file::read(frag_0_0_path_str)) {
        XCTAssertEqual(result.value().size(), 2);
        auto iterator = result.value().begin();
        XCTAssertEqual(iterator->first, 0);
        XCTAssertEqual(iterator->second.get<int64_t>(), 100);
        ++iterator;
        XCTAssertEqual(iterator->first, 0);
        XCTAssertEqual(iterator->second.get<boolean>(), true);
    } else {
        XCTAssert(0);
    }

    track.erase_module(module3, {0, 1});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertTrue(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(frag_0_0_path_str));
    if (auto result = playing::numbers_file::read(frag_0_0_path_str)) {
        XCTAssertEqual(result.value().size(), 1);
        XCTAssertEqual(result.value().begin()->first, 0);
        XCTAssertEqual(result.value().begin()->second.get<int64_t>(), 100);
    } else {
        XCTAssert(0);
    }

    track.erase_module(module1, {0, 1});

    queue.wait_until_all_tasks_are_finished();

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch0_path, 0}.string()));
    XCTAssertTrue(file_manager::content_exists(path::fragment{ch1_path, 1}.string()));

    timeline.erase_track(0);

    queue.wait_until_all_tasks_are_finished();

    XCTAssertFalse(file_manager::content_exists(path::fragment{ch1_path, 1}.string()));
}

@end
