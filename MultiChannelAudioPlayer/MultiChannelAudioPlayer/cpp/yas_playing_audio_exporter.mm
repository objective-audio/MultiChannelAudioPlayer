//
//  yas_playing_audio_exporter.mm
//

#include "yas_playing_audio_exporter.h"
#include "yas_audio_file.h"
#include "yas_cf_utils.h"
#include "yas_file_manager.h"
#include "yas_math.h"
#include "yas_operation.h"
#include "yas_playing_url_utils.h"

using namespace yas;
using namespace yas::playing;

struct audio_exporter::impl : base::impl {
    struct cancel_id : base {
        struct impl : base::impl {};
        cancel_id() : base(std::make_shared<impl>()) {
        }
    };

    audio::format const _format;
    url const _root_url;
    operation_queue _queue;
    cancel_id _cancel_id;
    audio::pcm_buffer _file_buffer;
    audio::pcm_buffer _process_buffer;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url, operation_queue &&queue)
        : _format({.sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url),
          _file_buffer(this->_format, static_cast<uint32_t>(sample_rate)),
          _process_buffer(this->_format, static_cast<uint32_t>(sample_rate)) {
        if (auto result = file_manager::create_directory_if_not_exists(this->_root_url.path()); result.is_error()) {
            std::runtime_error(to_string(result.error()));
        }
    }

    void update_format(double const sample_rate, audio::pcm_format const pcm_format) {
#warning todo
    }

    void export_file(uint32_t const ch_idx, proc::time::range const &range,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> &&proc_handler,
                     std::function<void(export_result_t const &)> &&result_handler) {
        auto ch_url = url_utils::channel_url(this->_root_url, ch_idx);

        operation op{
            [ch_idx, range, proc_handler = std::move(proc_handler), result_handler = std::move(result_handler),
             format = this->_format, ch_url = std::move(ch_url), file_buffer = this->_file_buffer,
             process_buffer = this->_process_buffer](operation const &operation) mutable {
                proc::length_t const sample_rate = format.sample_rate();
                proc::length_t const file_length = sample_rate;

                proc::frame_index_t file_frame_idx = math::floor_int(range.frame, file_length);
                proc::frame_index_t const end_frame_idx = range.next_frame();

                export_result_t export_result{nullptr};

                if (auto result = file_manager::create_directory_if_not_exists(ch_url.path())) {
                    while (file_frame_idx < end_frame_idx) {
                        if (operation.is_canceled()) {
                            return;
                        }

                        auto const file_url = url_utils::caf_url(ch_url, file_frame_idx, sample_rate);
                        proc::time::range const file_range{file_frame_idx, file_length};

                        // 1秒バッファをクリアする
                        file_buffer.clear();

                        if (operation.is_canceled()) {
                            return;
                        }

                        // ファイルがあれば1秒バッファへの読み込み
                        if (auto result = audio::make_opened_file(
                                {.file_url = file_url, .pcm_format = format.pcm_format(), .interleaved = false});
                            result.is_success()) {
                            audio::file &file = result.value();
                            if (file.processing_format() == format && file.file_length() == file_length) {
                                file.read_into_buffer(file_buffer);
                            }
                            file.close();
                        }

                        if (operation.is_canceled()) {
                            return;
                        }

                        // ファイルがあれば消す
                        if (auto result = file_manager::remove_file(file_url.path()); result.is_error()) {
                            export_result = export_result_t{export_error::erase_file_failed};
                            break;
                        }

                        // 処理をする範囲を調べる
                        auto opt_process_range = file_range.intersect(range);
                        if (!opt_process_range) {
                            export_result = export_result_t{export_error::invalid_process_range};
                            break;
                        }
                        proc::time::range const &process_range = *opt_process_range;

                        // 処理バッファをリセットして長さを合わせる
                        process_buffer.reset();
                        process_buffer.set_frame_length(static_cast<uint32_t>(process_range.length));

                        if (operation.is_canceled()) {
                            return;
                        }

                        // 作業バッファへの書き込みをクロージャで行う
                        proc_handler(process_buffer, process_range);

                        if (operation.is_canceled()) {
                            return;
                        }

                        // 作業バッファから1秒バッファへのコピー
                        if (auto result = file_buffer.copy_from(
                                process_buffer,
                                {.to_begin_frame = static_cast<uint32_t>(process_range.frame - file_frame_idx),
                                 .length = static_cast<uint32_t>(process_range.length)});
                            result.is_error()) {
                            export_result = export_result_t{export_error::copy_buffer_failed};
                            break;
                        }

                        if (operation.is_canceled()) {
                            return;
                        }

                        // 1秒バッファからファイルへの書き込み
                        if (auto result = audio::make_created_file(
                                {.file_url = file_url,
                                 .file_type = audio::file_type::core_audio_format,
                                 .pcm_format = format.pcm_format(),
                                 .interleaved = false,
                                 .settings = audio::wave_file_settings(format.sample_rate(), 1,
                                                                       format.sample_byte_count() * 8)})) {
                            audio::file &file = result.value();
                            if (auto write_result = file.write_from_buffer(file_buffer); write_result.is_error()) {
                                export_result = export_result_t{export_error::write_failed};
                                file.close();
                                break;
                            }
                            file.close();
                        } else {
                            export_result = export_result_t{export_error::create_file_failed};
                            break;
                        }

                        file_frame_idx += file_length;
                    }
                } else {
                    export_result = export_result_t{export_error::create_dir_failed};
                }

                dispatch_async(dispatch_get_main_queue(),
                               [result_handler = std::move(result_handler), export_result = std::move(export_result)] {
                                   result_handler(export_result);
                               });
            },
            {.identifier = this->_cancel_id}};
        this->_queue.push_back(std::move(op));
    }

    void clear_all_files(std::function<void(clear_result_t const &)> result_handler) {
        this->_queue.cancel();

        operation op([result_handler, root_url = this->_root_url](operation const &) {
            if (auto result = file_manager::remove_file(root_url.path())) {
                result_handler(clear_result_t{nullptr});
            } else {
                result_handler(clear_result_t{clear_error::remove_failed});
            }
        });
        this->_queue.push_back(std::move(op));
    }
};

audio_exporter::audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url,
                               operation_queue queue)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url, std::move(queue))) {
}

audio_exporter::audio_exporter(std::nullptr_t) : base(nullptr) {
}

void audio_exporter::update_format(double const sample_rate, audio::pcm_format const pcm_format) {
    impl_ptr<impl>()->update_format(sample_rate, pcm_format);
}

void audio_exporter::export_file(uint32_t const ch_idx, proc::time::range const &range,
                                 std::function<void(audio::pcm_buffer &, proc::time::range const &)> proc_handler,
                                 std::function<void(export_result_t const &)> completion_handler) {
    impl_ptr<impl>()->export_file(ch_idx, range, std::move(proc_handler), std::move(completion_handler));
}

void audio_exporter::clear(std::function<void(clear_result_t const &)> result_handler) {
    impl_ptr<impl>()->clear_all_files(result_handler);
}

double audio_exporter::sample_rate() const {
    return impl_ptr<impl>()->_format.sample_rate();
}

audio::pcm_format audio_exporter::pcm_format() const {
    return impl_ptr<impl>()->_format.pcm_format();
}

#pragma mark -

std::string yas::to_string(playing::audio_exporter::export_error const &error) {
    switch (error) {
        case playing::audio_exporter::export_error::erase_file_failed:
            return "erase_file_failed";
        case playing::audio_exporter::export_error::invalid_process_range:
            return "invalid_process_range";
        case playing::audio_exporter::export_error::copy_buffer_failed:
            return "copy_buffer_failed";
        case playing::audio_exporter::export_error::write_failed:
            return "write_failed";
        case playing::audio_exporter::export_error::create_file_failed:
            return "create_file_failed";
        case playing::audio_exporter::export_error::create_dir_failed:
            return "create_dir_failed";
    }
}
