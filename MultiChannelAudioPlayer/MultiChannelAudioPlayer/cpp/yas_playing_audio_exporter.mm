//
//  yas_playing_audio_exporter.mm
//

#include "yas_playing_audio_exporter.h"
#include "yas_cf_utils.h"
#include "yas_file_manager.h"
#include "yas_math.h"
#include "yas_operation.h"
#include "yas_playing_url.h"

using namespace yas::playing;

struct audio_exporter::impl : base::impl {
    audio::format _format;
    url const _root_url;
    operation_queue _queue;
    audio::pcm_buffer _file_buffer;
    audio::pcm_buffer _process_buffer;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url),
          _file_buffer(this->_format, static_cast<uint32_t>(sample_rate)),
          _process_buffer(this->_format, static_cast<uint32_t>(sample_rate)) {
        if (auto result = file_manager::create_directory_if_not_exists(this->_root_url.path()); result.is_error()) {
            std::runtime_error(to_string(result.error()));
        }
    }

    void export_file(uint32_t const trk_idx, proc::time::range const &range,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> &&proc_handler,
                     std::function<void(export_result_t const &)> &&result_handler) {
        auto trk_url = playing::channel_url(this->_root_url, trk_idx);

        operation op([trk_idx, range, proc_handler = std::move(proc_handler),
                      result_handler = std::move(result_handler), format = this->_format, trk_url = std::move(trk_url),
                      file_buffer = this->_file_buffer,
                      process_buffer = this->_process_buffer](operation const &operation) mutable {
            proc::length_t const sample_rate = format.sample_rate();
            proc::length_t const file_length = sample_rate;

            proc::frame_index_t file_frame_idx = math::floor_int(range.frame, file_length);
            proc::frame_index_t const end_frame_idx = range.next_frame();

            export_result_t export_result{nullptr};

            if (auto result = file_manager::create_directory_if_not_exists(trk_url.path())) {
                while (file_frame_idx < end_frame_idx) {
                    auto const file_url = playing::file_url(trk_url, file_frame_idx, sample_rate);
                    proc::time::range const file_range{file_frame_idx, file_length};

                    // 1秒バッファをクリアする
                    file_buffer.clear();

                    // ファイルがあれば1秒バッファへの読み込み
                    if (auto result = audio::make_opened_file(
                            {.file_url = file_url.cf_url(), .pcm_format = format.pcm_format(), .interleaved = false});
                        result.is_success()) {
                        audio::file &file = result.value();
                        if (file.processing_format() == format && file.file_length() == file_length) {
                            file.read_into_buffer(file_buffer);
                        }
                        file.close();
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

                    // 作業バッファへの書き込みをクロージャで行う
                    proc_handler(process_buffer, process_range);

                    // 作業バッファから1秒バッファへのコピー
                    if (auto result = file_buffer.copy_from(process_buffer, 0,
                                                            static_cast<uint32_t>(process_range.frame - file_frame_idx),
                                                            static_cast<uint32_t>(process_range.length));
                        result.is_error()) {
                        export_result = export_result_t{export_error::copy_buffer_failed};
                        break;
                    }

                    // 1秒バッファからファイルへの書き込み
                    if (auto result =
                            audio::make_created_file({.file_url = file_url.cf_url(),
                                                      .file_type = audio::file_type::core_audio_format,
                                                      .pcm_format = format.pcm_format(),
                                                      .interleaved = false,
                                                      .settings = audio::wave_file_settings(
                                                          format.sample_rate(), 1, format.sample_byte_count() * 8)})) {
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
            }

            dispatch_async(dispatch_get_main_queue(),
                           [result_handler = std::move(result_handler), export_result = std::move(export_result)] {
                               result_handler(export_result);
                           });
        });
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
    }
};

audio_exporter::audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url)) {
}

void audio_exporter::export_file(uint32_t const trk_idx, proc::time::range const &range,
                                 std::function<void(audio::pcm_buffer &, proc::time::range const &)> proc_handler,
                                 std::function<void(export_result_t const &)> completion_handler) {
    impl_ptr<impl>()->export_file(trk_idx, range, std::move(proc_handler), std::move(completion_handler));
}

void audio_exporter::clear_all_files(std::function<void(clear_result_t const &)> result_handler) {
    impl_ptr<impl>()->clear_all_files(result_handler);
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
    }
}
