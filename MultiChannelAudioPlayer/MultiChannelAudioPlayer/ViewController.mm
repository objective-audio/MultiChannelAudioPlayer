//
//  ViewController.m
//

#import "ViewController.h"
#import "yas_audio_math.h"
#import "yas_playing_audio.h"
#import "yas_system_url_utils.h"

#import <iostream>

using namespace yas;
using namespace yas::playing;

@interface ViewController ()

@end

namespace yas::playing::sample {
struct view_controller_cpp {
    url root_url{system_url_utils::directory_url(system_url_utils::dir::document).appending("sample")};
    audio_coordinator coordinator{this->root_url};
};
}

@implementation ViewController {
    sample::view_controller_cpp _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)exportSine:(UIButton *)sender {
    audio_coordinator &coordinator = self->_cpp.coordinator;
    double const sample_rate = coordinator.sample_rate();

    proc::time::range process_range{0, proc::length_t(sample_rate)};
    proc::timeline timeline;
    proc::track_index_t trk_idx = 0;

    if (proc::track &track = timeline.add_track(trk_idx++)) {
        proc::module module = proc::make_signal_module<Float32>(proc::generator::kind::second, 0);
        module.connect_output(proc::to_connector_index(proc::generator::output::value), 0);
        track.insert_module(process_range, std::move(module));
    }

    if (proc::track &track = timeline.add_track(trk_idx++)) {
        proc::module module = proc::make_signal_module<Float32>(audio::math::two_pi * 1000.0);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
        track.insert_module(process_range, std::move(module));
    }

    if (proc::track &track = timeline.add_track(trk_idx++)) {
        proc::module module = proc::make_signal_module<Float32>(proc::math1::kind::sin);
        module.connect_input(proc::to_connector_index(proc::math1::input::parameter), 0);
        module.connect_output(proc::to_connector_index(proc::math1::output::result), 0);
        track.insert_module(process_range, std::move(module));
    }

    if (auto &track = timeline.add_track(trk_idx++)) {
        auto module = proc::make_signal_module<Float32>(0.1f);
        module.connect_output(proc::to_connector_index(proc::constant::output::value), 1);
        track.insert_module(process_range, std::move(module));
    }

    if (auto &track = timeline.add_track(trk_idx++)) {
        auto module = proc::make_signal_module<Float32>(proc::math2::kind::multiply);
        module.connect_input(proc::to_connector_index(proc::math2::input::left), 0);
        module.connect_input(proc::to_connector_index(proc::math2::input::right), 1);
        module.connect_output(proc::to_connector_index(proc::math2::output::result), 0);
        track.insert_module(process_range, std::move(module));
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

    coordinator.set_export_proc_handler(
        [event_pair = *filtered_events.begin()](uint32_t const ch_idx, audio::pcm_buffer &buffer,
                                                proc::time::range const &range) mutable {
            audio::format const &format = buffer.format();
            if (format.pcm_format() == audio::pcm_format::float32 && format.channel_count() == 1) {
                if (event_pair.first == range) {
                    proc::signal_event const &event = event_pair.second;
                    Float32 const *event_data = event.data<Float32>();
                    buffer.copy_from(event_data, 1, 0, 0, 0, buffer.frame_length());
                }
            }
        });

    coordinator.export_file(0, process_range);
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
