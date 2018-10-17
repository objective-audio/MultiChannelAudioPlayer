//
//  yas_multi_track_signal_exporter.mm
//

#include "yas_multi_track_signal_exporter.h"

using namespace yas::multi_track;

struct signal_exporter::impl : base::impl {
    audio::format _format;
    std::string const _root_path;

    impl(double const sample_rate, audio::pcm_format const pcm_format, std::string const &root_path)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_path(root_path) {
    }
};

signal_exporter::signal_exporter(double const sample_rate, audio::pcm_format const pcm_format,
                                 std::string const &root_path)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_path)) {
}
