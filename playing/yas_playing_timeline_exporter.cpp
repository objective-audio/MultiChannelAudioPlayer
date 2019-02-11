//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_operation.h>
#include <processing/yas_processing_umbrella.h>
#include "yas_playing_audio_types.h"

using namespace yas;
using namespace yas::playing;

struct timeline_exporter::impl : base::impl {
    url const _root_url;
    operation_queue _queue;

    impl(url const &root_url, operation_queue &&queue) : _root_url(root_url), _queue(std::move(queue)) {
    }

    void set_timeline(proc::timeline &&timeline, timeline_exporter &exporter) {
        this->_src_timeline = std::move(timeline);

        this->_pool.invalidate();
        this->_pool += this->_src_timeline.chain()
                           .perform([weak_exporter = to_weak(exporter)](proc::timeline::event_t const &event) {
                               if (auto exporter = weak_exporter.lock()) {
                                   exporter.impl_ptr<impl>()->_timeline_event(event, exporter);
                               }
                           })
                           .sync();
    }

   private:
    proc::timeline _src_timeline = nullptr;
    proc::timeline _timeline;  // バックグラウンドからのみ触るようにする
    chaining::observer_pool _pool;

    void _timeline_event(proc::timeline::event_t const &event, timeline_exporter &exporter) {
        switch (event.type()) {
            case proc::timeline::event_type_t::fetched: {
                this->_replace_timeline(event.get<proc::timeline::fetched_event_t>(), exporter);
            } break;
            case proc::timeline::event_type_t::inserted: {
                this->_insert_tracks(event.get<proc::timeline::inserted_event_t>(), exporter);
            } break;
            case proc::timeline::event_type_t::erased: {
                this->_erase_tracks(event.get<proc::timeline::erased_event_t>(), exporter);
            } break;
            case proc::timeline::event_type_t::relayed: {
                this->_relayed_event(event.get<proc::timeline::relayed_event_t>());
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _relayed_event(proc::timeline::relayed_event_t const &event) {
        switch (event.relayed.type()) {
            case proc::track::event_type_t::fetched: {
            } break;
            case proc::track::event_type_t::inserted: {
            } break;
            case proc::track::event_type_t::erased: {
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _replace_timeline(proc::timeline::fetched_event_t const &event, timeline_exporter &exporter) {
        this->_queue.cancel_all();

        auto tracks = proc::copy_tracks(event.elements);
        operation op{[tracks = std::move(tracks), weak_exporter = to_weak(exporter)](auto const &) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto exporter_impl = exporter.impl_ptr<impl>();
                             exporter_impl->_timeline = proc::timeline{std::move(tracks)};
                             // 全てをexportする
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};

        this->_queue.push_back(std::move(op));
    }

    void _insert_tracks(proc::timeline::inserted_event_t const &event, timeline_exporter &exporter) {
        // 同じtrackのexportをキャンセル

        auto tracks = proc::copy_tracks(event.elements);
        operation op{[tracks = std::move(tracks), weak_exporter = to_weak(exporter)](auto const &) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto exporter_impl = exporter.impl_ptr<impl>();
                             auto &timeline = exporter_impl->_timeline;
                             for (auto &pair : tracks) {
                                 timeline.insert_track(pair.first, std::move(pair.second));
                             }
                             // trackのフォルダを一旦消す？
                             // trackをexportする
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};
    }

    void _erase_tracks(proc::timeline::erased_event_t const &event, timeline_exporter &exporter) {
        // 同じtrackのexportをキャンセル

        auto track_indices =
            to_vector<proc::track_index_t>(event.elements, [](auto const &pair) { return pair.first; });
        operation op{
            [track_indices = std::move(track_indices), weak_exporter = to_weak(exporter)](auto const &) mutable {
                if (auto exporter = weak_exporter.lock()) {
                    auto exporter_impl = exporter.impl_ptr<impl>();
                    auto &timeline = exporter_impl->_timeline;
                    for (auto const &trk_idx : track_indices) {
                        timeline.erase_track(trk_idx);
                    }
                    // trackのフォルダをまるっと削除する
                }
            },
            {.priority = playing::queue_priority::exporter}};
    }

    void _insert_modules() {
    }

    void _erase_modules() {
    }
};

timeline_exporter::timeline_exporter(url const &root_url, operation_queue queue)
    : base(std::make_shared<impl>(root_url, std::move(queue))) {
}

timeline_exporter::timeline_exporter(std::nullptr_t) : base(nullptr) {
}

void timeline_exporter::set_timeline(proc::timeline timeline) {
    impl_ptr<impl>()->set_timeline(std::move(timeline), *this);
}
