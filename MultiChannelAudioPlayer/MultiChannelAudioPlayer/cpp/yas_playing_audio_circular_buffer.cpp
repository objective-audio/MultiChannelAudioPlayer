//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <deque>
#include <mutex>
#include "yas_audio_file.h"
#include "yas_audio_format.h"
#include "yas_fast_each.h"
#include "yas_math.h"
#include "yas_result.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    struct container {
        enum state {
            unloaded,
            loaded,
        };

        using write_result_t = result<std::nullptr_t, audio::file::read_error_t>;
        using read_result_t = result<std::nullptr_t, audio::pcm_buffer::copy_error_t>;

        container(audio::pcm_buffer &&buffer) : _buffer(std::move(buffer)) {
        }

        bool contains(int64_t const frame) {
            return this->_begin_frame <= frame && frame < (this->_begin_frame + this->_buffer.frame_length());
        }

        void prepare_loading(int64_t const frame) {
            this->_state = container::state::unloaded;
            this->_begin_frame = frame;
        }

        write_result_t write_from_file(audio::file &file) {
            if (auto result = file.read_into_buffer(this->_buffer, this->_buffer.frame_length())) {
                this->_state = state::loaded;
                return write_result_t{nullptr};
            } else {
                return write_result_t{result.error()};
            }
        }

        read_result_t read_into_buffer(audio::pcm_buffer &to_buffer, uint32_t const to_frame, int64_t const play_frame,
                                       uint32_t const length) {
            if (this->_state != state::loaded) {
                return read_result_t{nullptr};
            }

            int64_t const from_frame = play_frame - this->_begin_frame;
            if (0 <= from_frame && from_frame < this->_begin_frame + this->_buffer.frame_length()) {
                //逆？
            }
            if (auto result = to_buffer.copy_from(this->_buffer, from_frame, to_frame, length)) {
                return read_result_t{nullptr};
            } else {
                return read_result_t{result.error()};
            }
        }

       private:
        audio::pcm_buffer _buffer;
        int64_t _begin_frame;
        state _state = state::unloaded;
    };

    using container_ptr = std::shared_ptr<container>;
    using container_wptr = std::weak_ptr<container>;

    impl(audio::format const &format, std::size_t const count, std::size_t const ch_idx, operation_queue &&queue)
        : _file_length(static_cast<uint32_t>(format.sample_rate())), _ch_idx(ch_idx), _queue(std::move(queue)) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto ptr = std::make_shared<container>(audio::pcm_buffer{format, this->_file_length});
            this->_loaded_containers.emplace_back(std::move(ptr));
        }
    }

    void read_into_buffer(audio::pcm_buffer &out_buffer) {
        uint32_t remain = out_buffer.frame_length();

        while (remain > 0) {
            int64_t const current = this->_current_frame;
            int64_t const current_begin_frame = math::floor_int(current, this->_file_length);
            uint32_t const proc_length = std::min(static_cast<uint32_t>(current - current_begin_frame), remain);

#warning containerを取り出すのではなく、頭のバッファを読み出せば良いのでは？
            container_ptr &container = this->_top_container_for_frame(current);
            if (container) {
                uint32_t const to_frame = this->_file_length - remain;
//                uint32_t const from_frame = static_cast<uint32_t>(current - current_begin_frame);
                if (auto result = container->read_into_buffer(out_buffer, to_frame, current, proc_length);
                    result.is_error()) {
                    throw std::runtime_error("circular_buffer container read_info_buffer error : " +
                                             to_string(result.error()));
                }
            }

            int64_t const next = current + proc_length;
            if (next % this->_file_length == 0) {
                if (container) {
                    container->prepare_loading(current_begin_frame +
                                               this->_file_length * this->_loaded_containers.size());
                    this->_load_top_container();
                    this->_load_containers();
                }
            }

            remain -= proc_length;
            this->_current_frame += proc_length;
        }
    }

    // readをロックした状態で使う
    container_ptr &_top_container_for_frame(int64_t const frame) {
        if (this->_loaded_containers.size() > 0) {
            container_ptr &container = this->_loaded_containers.front();
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
    std::deque<container_ptr> _loaded_containers;
    std::deque<container_ptr> _loading_containers;
    operation_queue _queue;
    int64_t _current_frame;

    void _load_containers() {
#warning todo オペレーションに投げる
#warning 同じcontainerをpush_cancel_idにする
        operation op{[ch_idx = this->_ch_idx](operation const &) {}};
        this->_queue.push_back(std::move(op));
    }

    void _load_top_container() {
        auto container = this->_loaded_containers.front();
        this->_loading_containers.push_back(container);
        this->_loaded_containers.pop_back();
        this->_load_containers();
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count,
                                             std::size_t const ch_idx, operation_queue queue)
    : base(std::make_shared<impl>(format, count, ch_idx, std::move(queue))) {
}

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read_into_buffer(out_buffer);
}
