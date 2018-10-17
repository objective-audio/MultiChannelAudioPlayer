//
//  yas_multi_track_signal_exporter.mm
//

#include "yas_multi_track_signal_exporter.h"

using namespace yas::multi_track;

struct signal_exporter::impl : base::impl {
    std::string _root_path;

    impl(std::string const &root_path) : _root_path(root_path) {
    }
};

signal_exporter::signal_exporter(std::string const &root_path) : base(std::make_shared<impl>(root_path)) {
}
