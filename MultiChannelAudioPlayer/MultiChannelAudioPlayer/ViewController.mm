//
//  ViewController.m
//

#import "ViewController.h"
#import <audio/yas_audio_math.h>
#import <cpp_utils/yas_system_path_utils.h>
#import <playing/yas_playing_umbrella.h>
#import <processing/yas_processing_umbrella.h>

#import <iostream>

using namespace yas;
using namespace yas::playing;

@interface ViewController ()

@end

namespace yas::playing::sample {
struct view_controller_cpp {
    std::string root_path =
        system_path_utils::directory_url(system_path_utils::dir::document).appending("sample").path();
    proc::sample_rate_t const sample_rate{48000};
#warning queueを共通にするかは後で考える
    playing::timeline_exporter timeline_exporter{this->root_path, yas::task_queue{}, this->sample_rate};
    audio_coordinator coordinator{this->root_path};
};
}

@implementation ViewController {
    sample::view_controller_cpp _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    std::cout << to_string(system_path_utils::directory_url(system_path_utils::dir::document)) << std::endl;
}

- (IBAction)exportSine:(UIButton *)sender {
    audio_coordinator &coordinator = self->_cpp.coordinator;
    double const sample_rate = coordinator.sample_rate();

    proc::time::range process_range{0, proc::length_t(sample_rate)};
    proc::timeline timeline;
    proc::track_index_t trk_idx = 0;

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        proc::module module = proc::make_signal_module<Float32>(proc::generator::kind::second, 0);
        module.connect_output(proc::to_connector_index(proc::generator::output::value), 0);
        track.push_back_module(std::move(module), process_range);
    }

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        proc::module module = proc::make_signal_module<Float32>(audio::math::two_pi * 1000.0);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
        track.push_back_module(std::move(module), process_range);
    }

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        auto module = proc::make_signal_module<Float32>(proc::math2::kind::multiply);
        module.connect_input(proc::to_connector_index(proc::math2::input::left), 0);
        module.connect_input(proc::to_connector_index(proc::math2::input::right), 1);
        module.connect_output(proc::to_connector_index(proc::math2::output::result), 0);
        track.push_back_module(std::move(module), process_range);
    }

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        proc::module module = proc::make_signal_module<Float32>(proc::math1::kind::sin);
        module.connect_input(proc::to_connector_index(proc::math1::input::parameter), 0);
        module.connect_output(proc::to_connector_index(proc::math1::output::result), 0);
        track.push_back_module(std::move(module), process_range);
    }

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        auto module = proc::make_signal_module<Float32>(0.1f);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
        track.push_back_module(std::move(module), process_range);
    }

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        auto module = proc::make_signal_module<Float32>(proc::math2::kind::multiply);
        module.connect_input(proc::to_connector_index(proc::math2::input::left), 0);
        module.connect_input(proc::to_connector_index(proc::math2::input::right), 1);
        module.connect_output(proc::to_connector_index(proc::math2::output::result), 0);
        track.push_back_module(std::move(module), process_range);
    }

    proc::sync_source sync_src{proc::sample_rate_t(sample_rate), process_range.length};
    proc::stream stream{sync_src};
    timeline.process(process_range, stream);

    if (!stream.has_channel(0)) {
        return;
    }

    auto const &channel = stream.channel(0);

    auto const filtered_events = channel.filtered_events<Float32, proc::signal_event>(
        [process_range](auto const &pair) { return pair.first == process_range; });

    if (filtered_events.size() == 0) {
        return;
    }
}

- (IBAction)start:(UIButton *)sender {
    self->_cpp.coordinator.set_playing(true);
}

- (IBAction)stop:(UIButton *)sender {
    self->_cpp.coordinator.set_playing(false);
}

- (IBAction)seek:(UIButton *)sender {
    self->_cpp.coordinator.seek(0);
}

@end
