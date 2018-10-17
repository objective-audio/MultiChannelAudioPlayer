//
//  yas_multi_track_signal_exporter.mm
//

#include "yas_multi_track_signal_exporter.h"
#include "yas_cf_utils.h"
#include "yas_operation.h"

using namespace yas::multi_track;

namespace yas::multi_track::utils {
#warning ディレクトリがなければ作る関数を追加
}

struct signal_exporter::impl : base::impl {
    audio::format _format;
    std::string const _root_path;
    operation_queue _queue;

    impl(double const sample_rate, audio::pcm_format const pcm_format, std::string const &root_path)
        : _format(audio::format::args{
              .sample_rate = sample_rate, .channel_count = 1, .pcm_format = pcm_format, .interleaved = false}),
          _root_path(root_path) {
        auto file_manager = [NSFileManager defaultManager];
        BOOL is_directory = NO;
        CFStringRef cf_path = to_cf_object(this->_root_path);
        auto file_exists = [file_manager fileExistsAtPath:(__bridge NSString *)cf_path isDirectory:&is_directory];
        if (!file_exists) {
#warning directoryを作成
        } else if (!is_directory) {
            throw std::runtime_error("root_path is file.");
        }
    }

    void export_file(uint32_t const trk_idx, proc::time::range const &range,
                     std::function<void(audio::pcm_buffer &, proc::time::range const &)> &&handler) {
        operation op([trk_idx, range, handler = std::move(handler)](operation const &) {
#warning todo
        });
        this->_queue.push_back(std::move(op));
    }
};

signal_exporter::signal_exporter(double const sample_rate, audio::pcm_format const pcm_format,
                                 std::string const &root_path)
    : base(std::make_shared<impl>(sample_rate, pcm_format, root_path)) {
}

void signal_exporter::export_file(uint32_t const trk_idx, proc::time::range const &range,
                                  std::function<void(audio::pcm_buffer &, proc::time::range const &)> handler) {
    impl_ptr<impl>()->export_file(trk_idx, range, std::move(handler));
}
