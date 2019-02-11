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

    void set_timeline(proc::timeline &&timeline, timeline_exporter &exporter) {
        this->_src_timeline = std::move(timeline);
        this->_timeline = proc::timeline{};

        this->_pool += this->_src_timeline.chain()
                           .perform([weak_exporter = to_weak(exporter)](proc::timeline::event_t const &event) {
                               auto exporter = weak_exporter.lock();
                               if (!exporter) {
                                   return;
                               }
                               auto exporter_impl = exporter.impl_ptr<impl>();

                               switch (event.type()) {
                                   case proc::timeline::event_type_t::fetched:
                                       exporter_impl->_queue.cancel_all();
                                       break;
                                   case proc::timeline::event_type_t::any:
                                       exporter_impl->_queue.cancel_all();
                                       // 全てのexportをキャンセル
                                       // timelineをcopyしてoperationに渡す
                                       // 全てをexportする
                                       break;
                                   case proc::timeline::event_type_t::inserted:
                                       // trackが追加された
                                       // 同じtrackのexportをキャンセル
                                       // trackをcopyしてoperationに渡す
                                       // trackをexportする
                                       break;
                                   case proc::timeline::event_type_t::erased:
                                       // trackが削除された
                                       // 同じtrackのexportをキャンセル
                                       // trackをoperation内で削除
                                       // ファイルを削除
                                       break;
                                   case proc::timeline::event_type_t::replaced:
                                       // trackが置き換えられた
                                       // 同じtrackのexportをキャンセル
                                       // trackをcopyしてoperationに渡す
                                       // trackをexportする
                                       break;
                                   case proc::timeline::event_type_t::relayed:
                                       // trackの内部が編集された
                                       break;
                               }
                           })
                           .sync();
    }

   private:
    proc::timeline _src_timeline = nullptr;
    proc::timeline _timeline;  // バックグラウンドからのみ触るようにする
    chaining::observer_pool _pool;
};

timeline_exporter::timeline_exporter(url const &root_url, operation_queue queue)
    : base(std::make_shared<impl>(root_url, std::move(queue))) {
}

timeline_exporter::timeline_exporter(std::nullptr_t) : base(nullptr) {
}

void timeline_exporter::set_timeline(proc::timeline timeline) {
    impl_ptr<impl>()->set_timeline(std::move(timeline), *this);
}
