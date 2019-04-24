//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_file_manager.h>
#include <cpp_utils/yas_operation.h>
#include <processing/yas_processing_umbrella.h>
#include "yas_playing_audio_types.h"
#include "yas_playing_math.h"
#include "yas_playing_timeline_canceling.h"
#include "yas_playing_timeline_utils.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct timeline_exporter::impl : base::impl {
    url const _root_url;
    operation_queue _queue;

    impl(url const &root_url, operation_queue &&queue, proc::sample_rate_t const sample_rate)
        : _root_url(root_url), _queue(std::move(queue)), _sample_rate(sample_rate) {
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

    void set_sample_rate(proc::sample_rate_t const sample_rate, timeline_exporter &exporter) {
        this->_sample_rate = sample_rate;
        this->_update_timeline(proc::copy_tracks(this->_src_timeline.tracks()), exporter);
    }

   private:
    proc::timeline _src_timeline = nullptr;
    proc::sample_rate_t _sample_rate;
    chaining::observer_pool _pool;

    struct background {
        proc::timeline timeline;
        std::optional<proc::sync_source> sync_source;
    };
    background _bg;

    void _timeline_event(proc::timeline::event_t const &event, timeline_exporter &exporter) {
        switch (event.type()) {
            case proc::timeline::event_type_t::fetched: {
                auto const fetched_event = event.get<proc::timeline::fetched_event_t>();
                this->_update_timeline(proc::copy_tracks(fetched_event.elements), exporter);
            } break;
            case proc::timeline::event_type_t::inserted: {
                this->_insert_tracks(event.get<proc::timeline::inserted_event_t>(), exporter);
            } break;
            case proc::timeline::event_type_t::erased: {
                this->_erase_tracks(event.get<proc::timeline::erased_event_t>(), exporter);
            } break;
            case proc::timeline::event_type_t::relayed: {
                this->_relayed_timeline_event(event.get<proc::timeline::relayed_event_t>(), exporter);
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _relayed_timeline_event(proc::timeline::relayed_event_t const &event, timeline_exporter &exporter) {
        switch (event.relayed.type()) {
            case proc::track::event_type_t::inserted: {
                this->_insert_modules(event.key, event.relayed.get<proc::track::inserted_event_t>(), exporter);
            } break;
            case proc::track::event_type_t::erased: {
                this->_erase_modules(event.key, event.relayed.get<proc::track::erased_event_t>(), exporter);
            } break;
            case proc::track::event_type_t::relayed: {
                this->_relayed_track_event(event.relayed.get<proc::track::relayed_event_t>(), event.key, exporter);
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _relayed_track_event(proc::track::relayed_event_t const &event, proc::track_index_t const trk_idx,
                              timeline_exporter &exporter) {
        switch (event.relayed.type()) {
            case proc::module_vector::event_type_t::inserted:
                this->_insert_module(trk_idx, event.key, event.relayed.get<proc::module_vector::inserted_event_t>(),
                                     exporter);
                break;
            case proc::module_vector::event_type_t::erased:
                this->_erase_module(trk_idx, event.key, event.relayed.get<proc::module_vector::erased_event_t>(),
                                    exporter);
                break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _update_timeline(proc::timeline::track_map_t &&tracks, timeline_exporter &exporter) {
        this->_queue.cancel_all();

        operation op{[tracks = std::move(tracks), sample_rate = this->_sample_rate,
                      weak_exporter = to_weak(exporter)](operation const &op) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto exporter_impl = exporter.impl_ptr<impl>();
                             exporter_impl->_bg.timeline = proc::timeline{std::move(tracks)};

                             if (op.is_canceled()) {
                                 return;
                             }

                             auto const &root_url = exporter_impl->_root_url;

                             auto result = file_manager::remove_file(root_url.path());
                             if (!result) {
                                 std::runtime_error("remove timeline root directory failed.");
                             }

                             if (op.is_canceled()) {
                                 return;
                             }

                             exporter_impl->_bg.sync_source.emplace(sample_rate, sample_rate);
                             auto const sync_source = *exporter_impl->_bg.sync_source;

                             proc::timeline &timeline = exporter_impl->_bg.timeline;

                             auto total_range = timeline.total_range();
                             if (!total_range.has_value()) {
                                 return;
                             }

                             proc::time::range const range =
                                 timeline_utils::fragment_range(*total_range, sync_source.sample_rate);

                             timeline.process(range, sync_source,
                                              [&op, &exporter_impl](proc::time::range const &range,
                                                                    proc::stream const &stream, bool &stop) {
                                                  if (op.is_canceled()) {
                                                      stop = true;
                                                      return;
                                                  }

                                                  exporter_impl->_export_fragments(range, stream);
                                              });
                         }
                     },
                     {.priority = playing::queue_priority::exporter}};

        this->_queue.push_back(std::move(op));
    }

    void _export_fragments(proc::time::range const &range, proc::stream const &stream) {
        for (auto const &ch_pair : stream.channels()) {
            auto const &ch_idx = ch_pair.first;
            auto const &channel = ch_pair.second;

            auto const fragment_path = url_utils::fragment_url(this->_root_url, ch_idx, range.frame).path();

            auto remove_result = file_manager::remove_file(fragment_path);
            if (!remove_result) {
                throw std::runtime_error("remove directory failed");
            }

            auto create_result = file_manager::create_directory_if_not_exists(fragment_path);
            if (!create_result) {
                throw std::runtime_error("create directory failed");
            }

            for (auto const &event_pair : channel.filtered_events<Float32, proc::signal_event>()) {
                proc::time::range const &range = event_pair.first;
                proc::signal_event const &event = event_pair.second;

#warning todo
            }
        }
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
                        exporter.impl_ptr<impl>()->_bg.timeline.insert_track(trk_idx, std::move(track));
                    }
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(pair.first)}};

            this->_queue.push_back(std::move(insert_op));
        }

        for (auto const &pair : tracks) {
            operation export_op{
                [trk_idx = pair.first, weak_exporter = to_weak(exporter)](auto const &) mutable {
#warning todo 差し替え前のトラックに関連するチャンネルのフォルダを削除
#warning todo トラックに関連するチャンネル全体をexport
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
                        exporter.impl_ptr<impl>()->_bg.timeline.erase_track(trk_idx);
                    }
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(trk_idx)}};

            this->_queue.push_back(std::move(op));
        }

        for (auto &trk_idx : track_indices) {
            operation op{
                [trk_idx = trk_idx, weak_exporter = to_weak(exporter)](auto const &) mutable {
#warning todo 差し替え前のトラックに関連するチャンネルのフォルダを削除
#warning todo 差し替え前のトラックに関連するチャンネルの範囲をexport
                },
                {.priority = playing::queue_priority::exporter, .cancel_id = timeline_cancel_matcher_id(trk_idx)}};

            this->_queue.push_back(std::move(op));
        }
    }

    void _insert_modules(proc::track_index_t const trk_idx, proc::track::inserted_event_t const &event,
                         timeline_exporter &exporter) {
        auto modules = proc::copy_to_modules(event.elements);

        for (auto const &pair : modules) {
            this->_queue.cancel_for_id(timeline_range_cancel_request_id(pair.first));
        }

        for (auto &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, modules = std::move(pair.second),
                          weak_exporter = to_weak(exporter)](auto const &) mutable {
                             if (auto exporter = weak_exporter.lock()) {
                                 auto &track = exporter.impl_ptr<impl>()->_bg.timeline.track(trk_idx);
                                 for (auto &module : modules) {
                                     track.push_back_module(std::move(module), range);
                                 }
                             }
                         },
                         {.priority = playing::queue_priority::exporter,
                          .cancel_id = timeline_cancel_matcher_id(trk_idx, range)}};

            this->_queue.push_back(std::move(op));
        }

        for (auto const &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, weak_exporter = to_weak(exporter)](operation const &op) mutable {
                             if (auto exporter = weak_exporter.lock()) {
                                 auto exporter_impl = exporter.impl_ptr<impl>();

                                 if (!exporter_impl->_bg.sync_source.has_value()) {
                                     return;
                                 }

                                 proc::sync_source const sync_source = *exporter_impl->_bg.sync_source;

                                 proc::time::range const range =
                                     timeline_utils::fragment_range(range, sync_source.sample_rate);

                                 exporter_impl->_bg.timeline.process(
                                     range, sync_source,
                                     [&op, &exporter_impl](proc::time::range const &range, proc::stream const &stream,
                                                           bool &stop) {
                                         if (op.is_canceled()) {
                                             stop = true;
                                             return;
                                         }

                                         exporter_impl->_export_fragments(range, stream);
                                     });
                             }
                         },
                         {.priority = playing::queue_priority::exporter,
                          .cancel_id = timeline_cancel_matcher_id(trk_idx, range)}};

            this->_queue.push_back(std::move(op));
        }
    }

    void _erase_modules(proc::track_index_t const trk_idx, proc::track::erased_event_t const &event,
                        timeline_exporter &exporter) {
        auto modules = proc::copy_to_modules(event.elements);

        for (auto const &pair : modules) {
            this->_queue.cancel_for_id(timeline_range_cancel_request_id(pair.first));
        }

        for (auto &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, module = std::move(pair.second),
                          weak_exporter = to_weak(exporter)](auto const &) mutable {
                             if (auto exporter = weak_exporter.lock()) {
                                 auto exporter_impl = exporter.impl_ptr<impl>();

//                                 exporter_impl->_bg.timeline.track(trk_idx).erase
#warning todo track内のmoduleを削除
                                 // 何かmoduleを一致させるidが必要では？
                                 // exporter.impl_ptr<impl>()->_bg.timeline.track(trk_idx).
                             }
                         },
                         {.priority = playing::queue_priority::exporter,
                          .cancel_id = timeline_cancel_matcher_id(trk_idx, range)}};

            this->_queue.push_back(std::move(op));
        }

        for (auto const &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, weak_exporter = to_weak(exporter)](auto const &) mutable {
                             if (auto exporter = weak_exporter.lock()) {
#warning todo moduleの範囲を削除しexport（1秒単位が良い？）
                             }
                         },
                         {.priority = playing::queue_priority::exporter,
                          .cancel_id = timeline_cancel_matcher_id(trk_idx, range)}};

            this->_queue.push_back(std::move(op));
        }
    }

    void _insert_module(proc::track_index_t const trk_idx, proc::time::range const range,
                        proc::module_vector::inserted_event_t const &event, timeline_exporter &exporter) {
#warning todo moduleがvectorに追加された場合
    }

    void _erase_module(proc::track_index_t const trk_idx, proc::time::range const range,
                       proc::module_vector::erased_event_t const &event, timeline_exporter &exporter) {
#warning todo moduleがvectorから削除された場合
    }
};

timeline_exporter::timeline_exporter(url const &root_url, operation_queue queue, proc::sample_rate_t const sample_rate)
    : base(std::make_shared<impl>(root_url, std::move(queue), sample_rate)) {
}

timeline_exporter::timeline_exporter(std::nullptr_t) : base(nullptr) {
}

void timeline_exporter::set_timeline(proc::timeline timeline) {
    impl_ptr<impl>()->set_timeline(std::move(timeline), *this);
}

void timeline_exporter::set_sample_rate(proc::sample_rate_t const sample_rate) {
    impl_ptr<impl>()->set_sample_rate(sample_rate, *this);
}
