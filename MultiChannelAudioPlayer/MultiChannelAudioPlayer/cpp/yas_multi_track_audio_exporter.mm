//
//  yas_multi_track_audio_exporter.mm
//

#include "yas_multi_track_audio_exporter.h"
#include <iostream>
#include "yas_cf_utils.h"
#include "yas_file_manager.h"
#include "yas_math.h"
#include "yas_operation.h"

using namespace yas::multi_track;

struct audio_exporter::impl : base::impl {
    audio::format _format;
    url const _root_url;
    operation_queue _queue;
    audio::pcm_buffer _one_sec_buffer;
    audio::pcm_buffer _process_buffer;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url),
          _one_sec_buffer(this->_format, static_cast<uint32_t>(sample_rate)),
          _process_buffer(this->_format, static_cast<uint32_t>(sample_rate)) {
        if (auto result = file_manager::create_directory_if_not_exists(this->_root_url.path()); result.is_error()) {
            std::runtime_error(to_string(result.error()));
        }
    }

    void export_file(uint32_t const trk_idx, proc::time::range const &range,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> &&handler) {
        auto trk_url = this->_root_url.appending(to_string(trk_idx));
        operation op([trk_idx, range, handler = std::move(handler), format = this->_format,
                      trk_url = std::move(trk_url), one_sec_buffer = this->_one_sec_buffer,
                      process_buffer = this->_process_buffer](operation const &) mutable {
            proc::length_t const sample_rate = format.sample_rate();
            proc::length_t const file_length = sample_rate;

            proc::frame_index_t file_frame_idx = math::floor_int(range.frame, file_length);
            proc::frame_index_t const end_frame_idx = file_frame_idx + file_length;

            while (file_frame_idx < end_frame_idx) {
                std::string const file_name = std::to_string(file_frame_idx / sample_rate) + ".caf";
                auto const file_url = trk_url.appending(file_name);
                proc::time::range const file_range{file_frame_idx, file_length};

                // バッファをクリアする
                one_sec_buffer.clear();

                // ファイルがあれば1秒バッファへの読み込み
                if (auto result = audio::make_opened_file(
                        {.file_url = file_url.cf_url(), .pcm_format = format.pcm_format(), .interleaved = false});
                    result.is_success() && result.value().file_format() == format &&
                    result.value().file_length() == file_length) {
                    audio::file &file = result.value();
                    file.read_into_buffer(one_sec_buffer);
                }

                // ファイルがあれば消す
                if (auto result = file_manager::remove_file(file_url.path()); result.is_error()) {
                    std::cout << "erase file error" << std::endl;
#warning 消せなかった場合はどうする？エラーを送信する？
                }

                // 処理をする範囲を調べる
                auto opt_process_range = file_range.intersect(range);
                if (!opt_process_range) {
                    break;
                }

                proc::time::range const &process_range = *opt_process_range;
                process_buffer.set_frame_length(static_cast<uint32_t>(process_range.length));

                // 作業バッファへの書き込みをクロージャで行う
                // 作業バッファから1秒バッファへのコピー
                // 1秒バッファからファイルへの書き込み
#warning todo
                file_frame_idx += file_length;
            }
        });
        this->_queue.push_back(std::move(op));
    }
};

audio_exporter::audio_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url)) {
}

void audio_exporter::export_file(uint32_t const trk_idx, proc::time::range const &range,
                                 std::function<void(audio::pcm_buffer &, proc::time::range const &)> handler) {
    impl_ptr<impl>()->export_file(trk_idx, range, std::move(handler));
}
