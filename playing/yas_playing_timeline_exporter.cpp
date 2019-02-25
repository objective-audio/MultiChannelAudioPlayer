//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_operation.h>
#include <processing/yas_processing_umbrella.h>
#include "yas_playing_audio_types.h"
#include "yas_playing_timeline_canceling.h"

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
                this->_relayed_event(event.get<proc::timeline::relayed_event_t>(), exporter);
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _relayed_event(proc::timeline::relayed_event_t const &event, timeline_exporter &exporter) {
        switch (event.relayed.type()) {
            case proc::track::event_type_t::inserted: {
                this->_insert_modules(event.key, event.relayed.get<proc::track::inserted_event_t>(), exporter);
            } break;
            case proc::track::event_type_t::erased: {
                this->_erase_modules(event.key, event.relayed.get<proc::track::erased_event_t>(), exporter);
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
                             // timelineのフォルダを削除する？
                             // 全てをexportする
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};

        this->_queue.push_back(std::move(op));
    }

    void _insert_tracks(proc::timeline::inserted_event_t const &event, timeline_exporter &exporter) {
        auto tracks = proc::copy_tracks(event.elements);

        for (auto const &pair : tracks) {
            this->_queue.cancel_for_id(timeline_track_cancel_request_id(pair.first));
        }

        for (auto &pair : tracks) {
            operation insert_op{
                [trk_idx = pair.first, track = std::move(pair.second),
                 weak_exporter = to_weak(exporter)](auto const &) mutable {
                    if (auto exporter = weak_exporter.lock()) {
                        exporter.impl_ptr<impl>()->_timeline.insert_track(trk_idx, std::move(track));
                    }
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(pair.first)}};

            this->_queue.push_back(std::move(insert_op));
        }

        for (auto const &pair : tracks) {
            operation export_op{
                [trk_idx = pair.first, weak_exporter = to_weak(exporter)](auto const &) mutable {
                    // TODO トラックのフォルダを削除
                    // TODO トラック全体をexport
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(pair.first)}};

            this->_queue.push_back(std::move(export_op));
        }
    }

    void _erase_tracks(proc::timeline::erased_event_t const &event, timeline_exporter &exporter) {
        auto track_indices =
            to_vector<proc::track_index_t>(event.elements, [](auto const &pair) { return pair.first; });

        for (auto const &trk_idx : track_indices) {
            this->_queue.cancel_for_id(timeline_track_cancel_request_id(trk_idx));
        }

        for (auto &trk_idx : track_indices) {
            operation op{
                [trk_idx = trk_idx, weak_exporter = to_weak(exporter)](auto const &) mutable {
                    if (auto exporter = weak_exporter.lock()) {
                        exporter.impl_ptr<impl>()->_timeline.erase_track(trk_idx);
                    }
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(trk_idx)}};

            this->_queue.push_back(std::move(op));
        }

        for (auto &trk_idx : track_indices) {
            operation op{
                [trk_idx = trk_idx, weak_exporter = to_weak(exporter)](auto const &) mutable {
                    // TODO トラックのフォルダを削除
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(trk_idx)}};

            this->_queue.push_back(std::move(op));
        }
    }

    void _insert_modules(proc::track_index_t const trk_idx, proc::track::inserted_event_t const &event,
                         timeline_exporter &exporter) {
        auto modules = proc::copy_modules(event.elements);

        for (auto const &pair : modules) {
            this->_queue.cancel_for_id(timeline_range_cancel_request_id(pair.first));
        }

        // TODO トラックと同じようにoperationを分ける
        operation op{[trk_idx, modules = std::move(modules), weak_exporter = to_weak(exporter)](auto const &) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto &timeline = exporter.impl_ptr<impl>()->_timeline;
                             for (auto &pair : modules) {
                                 timeline.track(trk_idx).insert_module(pair.first, std::move(pair.second));
                             }
                             // moduleの範囲を削除しexport（1秒単位が良い？）
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};

        this->_queue.push_back(std::move(op));
    }

    void _erase_modules(proc::track_index_t const trk_idx, proc::track::erased_event_t const &event,
                        timeline_exporter &exporter) {
        auto modules = proc::copy_modules(event.elements);

        // TODO moduleの範囲に完全に含まれるoperationをキャンセル

        // TODO トラックと同じようにoperationを分ける
        operation op{[trk_idx, modules = std::move(modules), weak_exporter = to_weak(exporter)](auto const &) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto &timeline = exporter.impl_ptr<impl>()->_timeline;
                             // track内のmoduleを削除
                             // 何かmoduleを一致させるidが必要では？
                             // moduleの範囲を削除しexport（1秒単位が良い？）
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};

        this->_queue.push_back(std::move(op));
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
