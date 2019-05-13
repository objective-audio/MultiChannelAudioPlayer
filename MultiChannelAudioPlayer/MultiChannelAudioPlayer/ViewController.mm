//
//  ViewController.m
//

#import "ViewController.h"
#import <audio/audio.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/playing.h>
#import <processing/processing.h>
#import <iostream>

using namespace yas;
using namespace yas::playing;

@interface ViewController ()

@end

namespace yas::playing::sample {
struct view_controller_cpp {
    std::string root_path =
        system_path_utils::directory_url(system_path_utils::dir::document).appending("sample").path();
    audio_coordinator coordinator{this->root_path};
#warning queueを共通にするかは後で考える
    playing::timeline_exporter timeline_exporter{this->root_path, yas::task_queue{queue_priority_count},
                                                 this->coordinator.sample_rate()};
    chaining::observer_pool pool;
};
}

@implementation ViewController {
    sample::view_controller_cpp _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self->_cpp.pool += self->_cpp.coordinator.configuration_chain()
                           .perform([&self](audio_configuration const &configuration) { [self exportSine]; })
                           .end();

    self->_cpp.pool +=
        self->_cpp.timeline_exporter.event_chain()
            .perform([&coordinator = self->_cpp.coordinator](playing::timeline_exporter::event const &event) {
                if (!event.result) {
                    return;
                }

                switch (event.result.value()) {
                    case timeline_exporter::method::reset:
                        coordinator.reload_all();
                        std::cout << "reset" << std::endl;
                        break;
                    case timeline_exporter::method::export_ended:
                        coordinator.reload(*event.range);
                        std::cout << "export ended " << to_string(*event.range) << std::endl;
                        break;
                    case timeline_exporter::method::export_began:
                        coordinator.reload(*event.range);
                        std::cout << "export began " << to_string(*event.range) << std::endl;
                        break;
                }
            })
            .end();

    std::cout << to_string(system_path_utils::directory_url(system_path_utils::dir::document)) << std::endl;
}

- (IBAction)exportSine:(UIButton *)sender {
    [self exportSine];
}

- (void)exportSine {
    audio_coordinator &coordinator = self->_cpp.coordinator;
    proc::sample_rate_t const sample_rate = std::round(coordinator.sample_rate());

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

    if (auto track = proc::track{}) {
        timeline.insert_track(trk_idx++, track);
        auto module = proc::make_signal_module<Float32>(proc::routing::kind::copy);
        module.connect_input(proc::to_connector_index(proc::routing::input::value), 0);
        module.connect_output(proc::to_connector_index(proc::routing::output::value), 1);
        track.push_back_module(std::move(module), process_range);
    }

    timeline_container container{"0", sample_rate, std::move(timeline)};

    self->_cpp.timeline_exporter.set_timeline_container(std::move(container));
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
