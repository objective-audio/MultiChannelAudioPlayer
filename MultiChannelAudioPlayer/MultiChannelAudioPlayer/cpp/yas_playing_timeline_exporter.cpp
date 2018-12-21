//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"

using namespace yas;
using namespace yas::playing;

struct timeline_exporter::impl : base::impl {
    url const _root_url;
    operation_queue _queue;
    proc::timeline _timeline = nullptr;

    impl(url const &root_url, operation_queue &&queue) : _root_url(root_url), _queue(std::move(queue)) {
    }
};

timeline_exporter::timeline_exporter(url const &root_url, operation_queue queue)
    : base(std::make_shared<impl>(root_url, std::move(queue))) {
}

timeline_exporter::timeline_exporter(std::nullptr_t) : base(nullptr) {
}
