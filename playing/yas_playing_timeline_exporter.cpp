//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"
#include <chaining/yas_chaining_umbrella.h>

using namespace yas;
using namespace yas::playing;

struct timeline_exporter::impl : base::impl {
    url const _root_url;
    operation_queue _queue;

    impl(url const &root_url, operation_queue &&queue) : _root_url(root_url), _queue(std::move(queue)) {
    }

    void set_timeline(proc::timeline &&timeline) {
        this->_timeline = std::move(timeline);
        
        this->_pool += this->_timeline.chain().perform([](proc::timeline_event_t const &event){
            switch (event.type) {
                case proc::timeline_event_type::fetched:
                case proc::timeline_event_type::any:
                    // 全部or何処かが変わった
                    break;
                case proc::timeline_event_type::inserted:
                    break;
                case proc::timeline_event_type::erased:
                    break;
                case proc::timeline_event_type::replaced:
                    break;
                case proc::timeline_event_type::relayed:
                    break;
            }
        }).sync();
    }

   private:
    proc::timeline _timeline = nullptr;
    chaining::observer_pool _pool;
};

timeline_exporter::timeline_exporter(url const &root_url, operation_queue queue)
    : base(std::make_shared<impl>(root_url, std::move(queue))) {
}

timeline_exporter::timeline_exporter(std::nullptr_t) : base(nullptr) {
}

void timeline_exporter::set_timeline(proc::timeline timeline) {
    impl_ptr<impl>()->set_timeline(std::move(timeline));
}
