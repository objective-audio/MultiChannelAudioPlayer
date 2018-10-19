//
//  yas_multi_track_signal_exporter.mm
//

#include "yas_multi_track_signal_exporter.h"
#include "yas_cf_utils.h"
#include "yas_file_manager.h"
#include "yas_operation.h"

using namespace yas::multi_track;

struct signal_exporter::impl : base::impl {
    audio::format _format;
    url const _root_url;
    operation_queue _queue;

    impl(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_url(root_url) {
        if (auto result = file_manager::create_directory_if_not_exists(this->_root_url.path()); result.is_error()) {
            std::runtime_error(to_string(result.error()));
        }
    }

    void export_file(uint32_t const trk_idx, proc::time::range const &range,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> &&handler) {
#warning pathで作る
        std::string path = this->_root_path + "/" + to_string(trk_idx);
        operation op([trk_idx, range, handler = std::move(handler), format = this->_format,
                      path = std::move(path)](operation const &) {
            proc::frame_index_t const sample_rate = format.sample_rate();
#warning マイナスを想定したい
            proc::frame_index_t const file_frame = range.frame - range.frame % sample_rate;
            proc::length_t const file_length = sample_rate;

            auto file_range = proc::time::range{file_frame, file_length};
#warning todo
        });
        this->_queue.push_back(std::move(op));
    }
};

signal_exporter::signal_exporter(double const sample_rate, audio::pcm_format const pcm_format, url const &root_url)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_url)) {
}

void signal_exporter::export_file(uint32_t const trk_idx, proc::time::range const &range,
                                  std::function<void(audio::pcm_buffer &, proc::time::range const &)> handler) {
    impl_ptr<impl>()->export_file(trk_idx, range, std::move(handler));
}
