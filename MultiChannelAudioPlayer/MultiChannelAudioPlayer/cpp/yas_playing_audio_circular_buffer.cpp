//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <mutex>
#include "yas_audio_file.h"
#include "yas_audio_format.h"
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_operation.h"
#include "yas_result.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    struct container {
        enum state {
            unloaded,
            loaded,
        };

        container(audio::pcm_buffer &&buffer) : _buffer(std::move(buffer)) {
        }

        bool contains(int64_t const frame) {
            return this->_begin_frame <= frame && frame < (this->_begin_frame + this->_buffer.frame_length());
        }

        void prepare_loading(int64_t const frame) {
            this->_state = container::state::unloaded;
            this->_begin_frame = frame;
        }

        void write_from_file(audio::file &file) {
            file.read_into_buffer(this->_buffer, this->_buffer.frame_length());
            this->_state = state::loaded;
        }

        void read_to_buffer(audio::pcm_buffer &to_buffer, int64_t const to_frame, int64_t const from_frame,
                            uint32_t const length) {
            if (this->_state != state::loaded) {
                return;
            }

#warning
        }

       private:
        audio::pcm_buffer _buffer;
        int64_t _begin_frame;
        state _state = state::unloaded;
    };

    using container_ptr = std::shared_ptr<container>;
    using container_wptr = std::weak_ptr<container>;

    impl(audio::format const &format, std::size_t const count, std::size_t const ch_idx)
        : _file_length(static_cast<uint32_t>(format.sample_rate())), _ch_idx(ch_idx) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto ptr = std::make_shared<container>(audio::pcm_buffer{format, this->_file_length});
            this->_containers.emplace_back(std::move(ptr));
        }
    }

    void read(audio::pcm_buffer &out_buffer) {
        uint32_t remain = out_buffer.frame_length();

        while (remain > 0) {
            std::lock_guard<std::recursive_mutex> lock(this->_read_mutex);

            int64_t const current = this->_current_frame;
            int64_t const current_begin_frame = math::floor_int(current, this->_file_length);
            uint32_t const proc_length = std::min(static_cast<uint32_t>(current - current_begin_frame), remain);
            container_ptr &container = this->_container_for_frame(current);
            if (container) {
#warning todo containerからデータを読み出す
#warning 同じcontainerをpush_cancel_idにする
                //                container_wptr weak_container = container;
                //                operation op{[weak_container](operation const &) {
                //                    if (auto container = weak_container.lock()) {
                //                        //                    container->write_from_file(<#audio::file &file#>)
                //                    }
                //                }};
                //                this->_queue.push_back(std::move(op));
            }
            int64_t const next = current + proc_length;
            if (next % this->_file_length == 0) {
                if (container) {
                    container->prepare_loading(current_begin_frame + this->_file_length * this->_containers.size());
                    this->_load_container(container);
                }
            }

            remain -= proc_length;
        }
    }

    // readをロックした状態で使う
    container_ptr &_container_for_frame(int64_t const frame) {
        for (auto &container : this->_containers) {
            if (container->contains(frame)) {
                return container;
            }
        }
        static container_ptr null_container = nullptr;
        return null_container;
    }

   private:
    int64_t const _ch_idx;
    uint32_t const _file_length;
    std::vector<container_ptr> _containers;
    operation_queue _queue;
    int64_t _current_frame;
    std::recursive_mutex _read_mutex;

    void _load_container(container_ptr &container) {
#warning todo オペレーションに投げる
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count,
                                             std::size_t const ch_idx)
    : base(std::make_shared<impl>(format, count, ch_idx)) {
}

void audio_circular_buffer::read(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read(out_buffer);
}
