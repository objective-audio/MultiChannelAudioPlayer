//
//  yas_multi_track_signal_exporter.cpp
//

#include "yas_multi_track_signal_exporter.h"

using namespace yas::multi_track;

struct signal_exporter::impl : base::impl {
    impl(std::string const &path) {
    }
};

signal_exporter::signal_exporter(std::string const &path) : base(std::make_shared<impl>(path)) {
}
