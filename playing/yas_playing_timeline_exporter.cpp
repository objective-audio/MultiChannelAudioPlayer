//
//  yas_playing_timeline_exporter.cpp
//

#include "yas_playing_timeline_exporter.h"
#include <audio/yas_audio_file.h>
#include <audio/yas_audio_pcm_buffer.h>
#include <chaining/yas_chaining_umbrella.h>
#include <cpp_utils/yas_fast_each.h>
#include <cpp_utils/yas_file_manager.h>
#include <cpp_utils/yas_operation.h>
#include <cpp_utils/yas_thread.h>
#include <processing/yas_processing_umbrella.h>
#include <fstream>
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
        assert(thread::is_main());

        this->_src_timeline = std::move(timeline);

        this->_pool.invalidate();
        this->_pool += this->_src_timeline.chain()
                           .perform([weak_exporter = to_weak(exporter)](proc::timeline::event_t const &event) {
                               if (auto exporter = weak_exporter.lock()) {
                                   exporter.impl_ptr<impl>()->_receive_timeline_event(event, exporter);
                               }
                           })
                           .sync();
    }

    void set_sample_rate(proc::sample_rate_t const sample_rate, timeline_exporter &exporter) {
        assert(thread::is_main());

        if (this->_sample_rate != sample_rate) {
            this->_sample_rate = sample_rate;
            this->_update_timeline(proc::copy_tracks(this->_src_timeline.tracks()), exporter);
        }
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

    void _receive_timeline_event(proc::timeline::event_t const &event, timeline_exporter &exporter) {
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
                this->_receive_relayed_timeline_event(event.get<proc::timeline::relayed_event_t>(), exporter);
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _receive_relayed_timeline_event(proc::timeline::relayed_event_t const &event, timeline_exporter &exporter) {
        switch (event.relayed.type()) {
            case proc::track::event_type_t::inserted: {
                this->_insert_modules(event.key, event.relayed.get<proc::track::inserted_event_t>(), exporter);
            } break;
            case proc::track::event_type_t::erased: {
                this->_erase_modules(event.key, event.relayed.get<proc::track::erased_event_t>(), exporter);
            } break;
            case proc::track::event_type_t::relayed: {
                this->_receive_relayed_track_event(event.relayed.get<proc::track::relayed_event_t>(), event.key,
                                                   exporter);
            } break;
            default:
                throw std::runtime_error("unreachable code.");
        }
    }

    void _receive_relayed_track_event(proc::track::relayed_event_t const &event, proc::track_index_t const trk_idx,
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
        assert(thread::is_main());

        this->_queue.cancel_all();

        operation op{[tracks = std::move(tracks), sample_rate = this->_sample_rate,
                      weak_exporter = to_weak(exporter)](operation const &op) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto exporter_impl = exporter.impl_ptr<impl>();
                             auto &bg = exporter_impl->_bg;
                             bg.timeline = proc::timeline{std::move(tracks)};
                             bg.sync_source.emplace(sample_rate, sample_rate);

                             if (op.is_canceled()) {
                                 return;
                             }

                             auto const &root_url = exporter_impl->_root_url;

                             auto result = file_manager::remove_content(root_url.path());
                             if (!result) {
                                 std::runtime_error("remove timeline root directory failed.");
                             }

                             if (op.is_canceled()) {
                                 return;
                             }

                             proc::timeline &timeline = exporter_impl->_bg.timeline;

                             auto total_range = timeline.total_range();
                             if (!total_range.has_value()) {
                                 return;
                             }

                             exporter_impl->_export_fragments(*total_range, op);
                         }
                     },
                     {.priority = playing::queue_priority::timeline}};

        this->_queue.push_back(std::move(op));
    }

    void _insert_tracks(proc::timeline::inserted_event_t const &event, timeline_exporter &exporter) {
        assert(thread::is_main());

        auto tracks = proc::copy_tracks(event.elements);

        std::optional<proc::time::range> total_range = proc::total_range(tracks);

        for (auto &pair : tracks) {
            operation insert_op{[trk_idx = pair.first, track = std::move(pair.second),
                                 weak_exporter = to_weak(exporter)](auto const &) mutable {
                                    if (auto exporter = weak_exporter.lock()) {
                                        exporter.impl_ptr<impl>()->_bg.timeline.insert_track(trk_idx, std::move(track));
                                    }
                                },
                                {.priority = playing::queue_priority::timeline}};

            this->_queue.push_back(std::move(insert_op));
        }

        if (total_range) {
            this->_push_export_operation(*total_range, exporter);
        }
    }

    void _erase_tracks(proc::timeline::erased_event_t const &event, timeline_exporter &exporter) {
        assert(thread::is_main());

        auto track_indices =
            to_vector<proc::track_index_t>(event.elements, [](auto const &pair) { return pair.first; });

        std::optional<proc::time::range> total_range = proc::total_range(event.elements);

        for (auto &trk_idx : track_indices) {
            operation erase_op{[trk_idx = trk_idx, weak_exporter = to_weak(exporter)](auto const &) mutable {
                                   if (auto exporter = weak_exporter.lock()) {
                                       exporter.impl_ptr<impl>()->_bg.timeline.erase_track(trk_idx);
                                   }
                               },
                               {.priority = playing::queue_priority::timeline}};

            this->_queue.push_back(std::move(erase_op));
        }

        if (total_range) {
            this->_push_export_operation(*total_range, exporter);
        }
    }

    void _insert_modules(proc::track_index_t const trk_idx, proc::track::inserted_event_t const &event,
                         timeline_exporter &exporter) {
        assert(thread::is_main());

        auto modules = proc::copy_to_modules(event.elements);

        for (auto &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, modules = std::move(pair.second),
                          weak_exporter = to_weak(exporter)](auto const &) mutable {
                             if (auto exporter = weak_exporter.lock()) {
                                 auto &track = exporter.impl_ptr<impl>()->_bg.timeline.track(trk_idx);
                                 assert(track.modules().count(range) == 0);
                                 for (auto &module : modules) {
                                     track.push_back_module(std::move(module), range);
                                 }
                             }
                         },
                         {.priority = playing::queue_priority::timeline}};

            this->_queue.push_back(std::move(op));
        }

        for (auto const &pair : modules) {
            auto const &range = pair.first;
            this->_push_export_operation(range, exporter);
        }
    }

    void _erase_modules(proc::track_index_t const trk_idx, proc::track::erased_event_t const &event,
                        timeline_exporter &exporter) {
        assert(thread::is_main());

        auto modules = proc::copy_to_modules(event.elements);

        for (auto &pair : modules) {
            auto const &range = pair.first;
            operation op{[trk_idx, range = range, module = std::move(pair.second),
                          weak_exporter = to_weak(exporter)](auto const &) mutable {
                             if (auto exporter = weak_exporter.lock()) {
                                 auto exporter_impl = exporter.impl_ptr<impl>();
                                 auto &track = exporter_impl->_bg.timeline.track(trk_idx);
                                 assert(track.modules().count(range) > 0);
                                 track.erase_modules_for_range(range);
                             }
                         },
                         {.priority = playing::queue_priority::timeline}};

            this->_queue.push_back(std::move(op));
        }

        for (auto const &pair : modules) {
            auto const &range = pair.first;
            this->_push_export_operation(range, exporter);
        }
    }

    void _insert_module(proc::track_index_t const trk_idx, proc::time::range const range,
                        proc::module_vector::inserted_event_t const &event, timeline_exporter &exporter) {
        assert(thread::is_main());

        operation op{[trk_idx, range, module_idx = event.index, module = event.element.copy(),
                      weak_exporter = to_weak(exporter)](auto const &) mutable {
                         if (auto exporter = weak_exporter.lock()) {
                             auto &track = exporter.impl_ptr<impl>()->_bg.timeline.track(trk_idx);
                             assert(track.modules().count(range) > 0);
                             track.insert_module(std::move(module), module_idx, range);
                         }
                     },
                     {.priority = playing::queue_priority::timeline}};

        this->_queue.push_back(std::move(op));

        this->_push_export_operation(range, exporter);
    }

    void _erase_module(proc::track_index_t const trk_idx, proc::time::range const range,
                       proc::module_vector::erased_event_t const &event, timeline_exporter &exporter) {
        assert(thread::is_main());

        operation op{
            [trk_idx, range, module_idx = event.index, weak_exporter = to_weak(exporter)](auto const &) mutable {
                if (auto exporter = weak_exporter.lock()) {
                    auto &track = exporter.impl_ptr<impl>()->_bg.timeline.track(trk_idx);
                    assert(track.modules().count(range) > 0);
                    track.erase_module_at(module_idx, range);
                }
            },
            {.priority = playing::queue_priority::timeline}};

        this->_push_export_operation(range, exporter);
    }

    void _push_export_operation(proc::time::range const &range, timeline_exporter &exporter) {
        operation export_op{[range, weak_exporter = to_weak(exporter)](operation const &op) {
                                if (auto exporter = weak_exporter.lock()) {
                                    auto exporter_impl = exporter.impl_ptr<impl>();
                                    if (!exporter_impl->_bg.sync_source.has_value()) {
                                        return;
                                    }

                                    auto const &sync_source = *exporter_impl->_bg.sync_source;

                                    proc::time::range const process_range =
                                        timeline_utils::fragments_range(range, sync_source.sample_rate);

                                    exporter_impl->_remove_fragments(process_range, op);
                                    exporter_impl->_export_fragments(process_range, op);
                                }
                            },
                            {.priority = playing::queue_priority::exporting}};

        this->_queue.push_back(std::move(export_op));
    }

    void _export_fragments(proc::time::range const &range, operation const &op) {
        assert(!thread::is_main());

        if (!this->_bg.sync_source.has_value()) {
            return;
        }

        auto const &sync_source = *this->_bg.sync_source;

        proc::time::range const process_range = timeline_utils::fragments_range(range, sync_source.sample_rate);

        this->_bg.timeline.process(process_range, sync_source,
                                   [&op, this](proc::time::range const &range, proc::stream const &stream, bool &stop) {
                                       if (op.is_canceled()) {
                                           stop = true;
                                           return;
                                       }

                                       this->_export_fragment(range, stream);
                                   });
    }

    void _export_fragment(proc::time::range const &range, proc::stream const &stream) {
        assert(!thread::is_main());

        auto const frag_idx = range.frame / this->_sample_rate;

        for (auto const &ch_pair : stream.channels()) {
            auto const &ch_idx = ch_pair.first;
            auto const &channel = ch_pair.second;

            auto const fragment_path = url_utils::fragment_url(this->_root_url, ch_idx, frag_idx).path();

#warning todo 事前に消すからいらなそう
            auto remove_result = file_manager::remove_content(fragment_path);
            if (!remove_result) {
                throw std::runtime_error("remove fragment directory failed");
            }

            if (channel.events().size() == 0) {
                return;
            }

            auto create_result = file_manager::create_directory_if_not_exists(fragment_path);
            if (!create_result) {
                throw std::runtime_error("create directory failed");
            }

            for (auto const &event_pair : channel.filtered_events<proc::signal_event>()) {
                proc::time::range const &range = event_pair.first;
                proc::signal_event const &event = event_pair.second;

                auto const signal_url =
                    url_utils::signal_file_url(this->_root_url, ch_idx, frag_idx, range, event.sample_type());

                std::ofstream stream{signal_url.path(), std::ios_base::out | std::ios_base::binary};
                if (!stream) {
                    throw std::runtime_error("open stream failed.");
                }

                if (char const *data = timeline_utils::char_data(event)) {
                    stream.write(data, event.byte_size());
                }

                stream.close();
            }

            if (auto const number_events = channel.filtered_events<proc::number_event>(); number_events.size() > 0) {
                auto const number_url = url_utils::number_file_url(this->_root_url, ch_idx, frag_idx);

                std::ofstream stream{number_url.path()};
                if (!stream) {
                    throw std::runtime_error("open stream failed.");
                }

                for (auto const &event_pair : number_events) {
                    proc::time::frame::type const &frame = event_pair.first;
                    proc::number_event const &event = event_pair.second;

                    stream << std::to_string(frame);
                    stream << ",";
                    stream << timeline_utils::to_string(event);
                    stream << ",";
                }

                stream.close();
            }
        }
    }

    void _remove_fragments(proc::time::range const &range, operation const &op) {
        assert(!thread::is_main());
        auto const &root_url = this->_root_url;

        auto ch_paths_result = file_manager::content_paths_in_directory(root_url.path());
        if (!ch_paths_result) {
            return;
        }

        auto const ch_names = to_vector<std::string>(ch_paths_result.value(),
                                                     [](auto const &path) { return url{path}.last_path_component(); });

        auto const begin_frag_idx = range.frame / this->_sample_rate;
        auto const end_frag_idx = range.next_frame() / this->_sample_rate;

        for (auto const &ch_name : ch_names) {
            if (op.is_canceled()) {
                return;
            }

            auto each = make_fast_each(begin_frag_idx, end_frag_idx);
            while (yas_each_next(each)) {
                auto const &frag_idx = yas_each_index(each);
                auto const frag_path = url_utils::fragment_url(root_url, std::stoll(ch_name), frag_idx).path();
                auto const remove_result = file_manager::remove_content(frag_path);
                if (!remove_result) {
                    throw std::runtime_error("remove fragment directory failed");
                }
            }
        }
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
