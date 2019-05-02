//
//  yas_playing_timeline_exporter_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import <processing/processing.h>
#import <fstream>

#import <iostream>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::timeline_exporter_test {
struct cpp {
    std::string root_path = system_path_utils::directory_url(system_path_utils::dir::document).appending("root").path();
    operation_queue queue{queue_priority_count};
};

static std::string string_from_number_file(std::string const &path) {
    auto stream = std::ifstream{path};
    return std::string((std::istreambuf_iterator<char>(stream)), std::istreambuf_iterator<char>());
}
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
    self->_cpp.queue.wait_until_all_operations_are_finished();
    file_manager::remove_content(self->_cpp.root_path);
}

- (void)test_initial {
    std::string const &root_path = self->_cpp.root_path;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_operations_are_finished();

    XCTAssertFalse(file_manager::content_exists(root_path));
}

- (void)test_set_timeline {
    std::string const &root_path = self->_cpp.root_path;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_path, queue, sample_rate};

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

    XCTAssertTrue(file_manager::content_exists(root_path));

    XCTAssertFalse(file_manager::content_exists(path_utils::channel_path(root_path, -1)));
    XCTAssertTrue(file_manager::content_exists(path_utils::channel_path(root_path, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::channel_path(root_path, 1)));
    XCTAssertFalse(file_manager::content_exists(path_utils::channel_path(root_path, 2)));

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, -2)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, -1)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 1)));
    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 2)));

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 4)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 5)));
    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 6)));

    XCTAssertTrue(
        file_manager::content_exists(path_utils::signal_file_path(root_path, 0, -1, {-2, 2}, typeid(int64_t))));
    XCTAssertTrue(file_manager::content_exists(path_utils::signal_file_path(root_path, 0, 0, {0, 2}, typeid(int64_t))));
    XCTAssertTrue(file_manager::content_exists(path_utils::signal_file_path(root_path, 0, 1, {2, 1}, typeid(int64_t))));

    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 1, 5)));

    int64_t values[2];

    values[0] = values[1] = 0;

    {
        auto stream = std::ifstream{path_utils::signal_file_path(root_path, 0, -1, {-2, 2}, typeid(int64_t)),
                                    std::ios_base::in | std::ios_base::binary};
        XCTAssertFalse(stream.fail());
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), sizeof(values));
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), 0);
        XCTAssertTrue(stream.eof());
    }

    values[0] = values[1] = 0;

    {
        auto stream = std::ifstream{path_utils::signal_file_path(root_path, 0, 0, {0, 2}, typeid(int64_t)),
                                    std::ios_base::in | std::ios_base::binary};
        XCTAssertFalse(stream.fail());
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), sizeof(values));
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), 0);
        XCTAssertTrue(stream.eof());
    }

    values[0] = values[1] = 0;

    {
        auto stream = std::ifstream{path_utils::signal_file_path(root_path, 0, 1, {2, 1}, typeid(int64_t)),
                                    std::ios_base::in | std::ios_base::binary};
        XCTAssertFalse(stream.fail());
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), sizeof(int64_t));
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 0);
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), 0);
        XCTAssertTrue(stream.eof());
    }

    {
        auto stream = std::ifstream{path_utils::number_file_path(root_path, 1, 5)};
        std::string str((std::istreambuf_iterator<char>(stream)), std::istreambuf_iterator<char>());
        XCTAssertEqual(str, "10,11,");
    }
}

- (void)test_set_sample_rate {
    std::string const &root_path = self->_cpp.root_path;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const pre_sample_rate = 2;
    proc::sample_rate_t const post_sample_rate = 3;

    timeline_exporter exporter{root_path, queue, pre_sample_rate};

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

    exporter.set_sample_rate(post_sample_rate);

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(root_path));

    XCTAssertFalse(file_manager::content_exists(path_utils::channel_path(root_path, -1)));
    XCTAssertTrue(file_manager::content_exists(path_utils::channel_path(root_path, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::channel_path(root_path, 1)));
    XCTAssertFalse(file_manager::content_exists(path_utils::channel_path(root_path, 2)));

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, -2)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, -1)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 1)));

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 2)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 3)));
    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 4)));

    XCTAssertTrue(
        file_manager::content_exists(path_utils::signal_file_path(root_path, 0, -1, {-2, 2}, typeid(int64_t))));
    XCTAssertTrue(file_manager::content_exists(path_utils::signal_file_path(root_path, 0, 0, {0, 3}, typeid(int64_t))));

    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 1, 3)));

    int64_t values[3];

    values[0] = values[1] = values[2] = 0;

    {
        auto stream = std::ifstream{path_utils::signal_file_path(root_path, 0, -1, {-2, 2}, typeid(int64_t)),
                                    std::ios_base::in | std::ios_base::binary};
        XCTAssertFalse(stream.fail());
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), sizeof(int64_t) * 2);
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        XCTAssertEqual(values[2], 0);
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), 0);
        XCTAssertTrue(stream.eof());
    }

    values[0] = values[1] = values[2] = 0;

    {
        auto stream = std::ifstream{path_utils::signal_file_path(root_path, 0, 0, {0, 3}, typeid(int64_t)),
                                    std::ios_base::in | std::ios_base::binary};
        XCTAssertFalse(stream.fail());
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), sizeof(values));
        XCTAssertEqual(values[0], 10);
        XCTAssertEqual(values[1], 10);
        XCTAssertEqual(values[2], 10);
        stream.read((char *)values, sizeof(values));
        XCTAssertEqual(stream.gcount(), 0);
        XCTAssertTrue(stream.eof());
    }

    values[0] = values[1] = values[2] = 0;

    {
        auto path = path_utils::number_file_path(root_path, 1, 3);
        auto str = timeline_exporter_test::string_from_number_file(path);
        XCTAssertEqual(str, "10,11,");
    }
}

- (void)test_update_timeline {
    std::string const &root_path = self->_cpp.root_path;
    operation_queue &queue = self->_cpp.queue;
    proc::sample_rate_t const sample_rate = 2;

    timeline_exporter exporter{root_path, queue, sample_rate};

    queue.wait_until_all_operations_are_finished();

    proc::timeline timeline;

    exporter.set_timeline(timeline);

    queue.wait_until_all_operations_are_finished();

    XCTAssertFalse(file_manager::content_exists(root_path));

    proc::track track;
    auto module1 = proc::make_number_module<int64_t>(100);
    module1.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    track.push_back_module(module1, {0, 1});

    timeline.insert_track(0, track);

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(root_path));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    XCTAssertEqual(timeline_exporter_test::string_from_number_file(path_utils::number_file_path(root_path, 0, 0)),
                   "0,100,");

    auto module2 = proc::make_number_module<Float64>(1.0);
    module2.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
    track.push_back_module(module2, {2, 1});

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));
    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 1, 1)));
    XCTAssertEqual(timeline_exporter_test::string_from_number_file(path_utils::number_file_path(root_path, 1, 1)),
                   "2,1.000000,");

    auto module3 = proc::make_number_module<Float64>(2.0);
    module3.connect_output(proc::to_connector_index(proc::constant::output::value), 0);
    track.push_back_module(module3, {0, 1});

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    XCTAssertEqual(timeline_exporter_test::string_from_number_file(path_utils::number_file_path(root_path, 0, 0)),
                   "0,100,0,2.000000,");

    track.erase_module(module3, {0, 1});

    queue.wait_until_all_operations_are_finished();

    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::number_file_path(root_path, 0, 0)));
    std::cout << timeline_exporter_test::string_from_number_file(path_utils::number_file_path(root_path, 0, 0))
              << std::endl;
    XCTAssertEqual(timeline_exporter_test::string_from_number_file(path_utils::number_file_path(root_path, 0, 0)),
                   "0,100,");

    track.erase_module(module1, {0, 1});

    queue.wait_until_all_operations_are_finished();

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 0, 0)));
    XCTAssertTrue(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));

    timeline.erase_track(0);

    queue.wait_until_all_operations_are_finished();

    XCTAssertFalse(file_manager::content_exists(path_utils::fragment_path(root_path, 1, 1)));
}

@end
