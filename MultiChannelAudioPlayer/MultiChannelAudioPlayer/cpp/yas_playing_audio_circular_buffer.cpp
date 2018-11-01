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
#include "yas_playing_url_utils.h"
#include "yas_result.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    struct container {
        enum state {
            unloaded,
            loaded,
        };

        enum class write_error {
            read_from_file_failed,
        };

        enum class read_error {
            locked,
            unloaded,
            out_of_range_play_frame,
            copy_failed,
        };

        using write_result_t = result<std::nullptr_t, write_error>;
        using read_result_t = result<std::nullptr_t, read_error>;

        container(audio::pcm_buffer &&buffer) : _buffer(std::move(buffer)) {
        }

        int64_t file_idx() const {
            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            return this->_begin_frame / static_cast<int64_t>(this->_buffer.format().sample_rate());
        }

        audio::format const &format() const {
            return this->_buffer.format();
        }

        bool contains(int64_t const frame) {
            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            return this->_begin_frame <= frame && frame < (this->_begin_frame + this->_buffer.frame_length());
        }

        void prepare_loading(int64_t const frame) {
            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            this->_state = container::state::unloaded;
            this->_begin_frame = frame;
        }

        write_result_t write_from_file(audio::file &file) {
            std::lock_guard<std::recursive_mutex> lock(this->_mutex);

            if (auto result = file.read_into_buffer(this->_buffer, this->_buffer.frame_length())) {
                this->_state = state::loaded;
                return write_result_t{nullptr};
            } else {
                return write_result_t{write_error::read_from_file_failed};
            }
        }

        read_result_t read_into_buffer(audio::pcm_buffer &to_buffer, uint32_t const to_frame, int64_t const play_frame,
                                       uint32_t const length) {
            auto lock = std::unique_lock<std::recursive_mutex>(this->_mutex, std::try_to_lock);
            if (!lock.owns_lock()) {
                return read_result_t{nullptr};
            }

            if (this->_state != state::loaded) {
                return read_result_t{nullptr};
            }

            int64_t const from_frame = play_frame - this->_begin_frame;

            if (from_frame < 0 || this->_begin_frame + this->_buffer.frame_length() <= from_frame) {
                return read_result_t{read_error::out_of_range_play_frame};
            }

            if (auto result = to_buffer.copy_from(this->_buffer, static_cast<uint32_t>(from_frame), to_frame, length)) {
                return read_result_t{nullptr};
            } else {
                return read_result_t{read_error::copy_failed};
            }
        }

       private:
        audio::pcm_buffer _buffer;
        int64_t _begin_frame;
        state _state = state::unloaded;

        std::recursive_mutex mutable _mutex;
    };

    using container_ptr = std::shared_ptr<container>;
    using container_wptr = std::weak_ptr<container>;

    impl(audio::format const &format, std::size_t const count, url const &ch_url, operation_queue &&queue)
        : _file_length(static_cast<uint32_t>(format.sample_rate())), _ch_url(ch_url), _queue(std::move(queue)) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto ptr = std::make_shared<container>(audio::pcm_buffer{format, this->_file_length});
            this->_loading_containers.emplace_back(std::move(ptr));
        }
        this->_load_containers();
    }

    void read_into_buffer(audio::pcm_buffer &out_buffer) {
        uint32_t remain = out_buffer.frame_length();

        while (remain > 0) {
            int64_t const current = this->_current_frame;
            int64_t const current_begin_frame = math::floor_int(current, this->_file_length);
            uint32_t const proc_length = std::min(static_cast<uint32_t>(current - current_begin_frame), remain);

            container_ptr &container = this->_top_container_for_frame(current);
            if (container) {
                uint32_t const to_frame = this->_file_length - remain;
                if (auto result = container->read_into_buffer(out_buffer, to_frame, current, proc_length);
                    result.is_error()) {
                    throw std::runtime_error("circular_buffer container read_info_buffer error : " +
                                             this->_to_string(result.error()));
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
    url const _ch_url;
    uint32_t const _file_length;
    std::deque<container_ptr> _loaded_containers;
    std::deque<container_ptr> _loading_containers;
    operation_queue _queue;
    int64_t _current_frame;

    void _load_containers() {
#warning todo オペレーションに投げる
#warning 同じcontainerをpush_cancel_idにする
        auto weak_circular_buffer = to_weak(cast<audio_circular_buffer>());
        operation op{[ch_url = this->_ch_url, weak_circular_buffer](operation const &) {
            if (audio_circular_buffer circular_buffer = weak_circular_buffer.lock()) {
                auto ip = circular_buffer.impl_ptr<impl>();
                auto &containers = ip->_loading_containers;

                while (containers.size() > 0) {
                    auto &container = containers.front();
                    auto const file_url = url_utils::caf_url(ch_url, container->file_idx());
                    auto result = audio::make_opened_file(audio::file::open_args{
                        .file_url = file_url.cf_url(),
                        .pcm_format = container->format().pcm_format(),
                        .interleaved = false,
                    });

                    ip->_loaded_containers.push_back(container);
                    containers.pop_front();
                }
            }
        }};
        this->_queue.push_back(std::move(op));
    }

    void _load_top_container() {
        auto container = this->_loaded_containers.front();
        this->_loading_containers.push_back(container);
        this->_loaded_containers.pop_back();
        this->_load_containers();
    }

    std::string to_string(container::write_error const &error) {
        switch (error) {
            case container::write_error::read_from_file_failed:
                return "read_from_file_failed";
        }
    }

    std::string _to_string(container::read_error const &error) {
        switch (error) {
            case container::read_error::locked:
                return "locked";
            case container::read_error::unloaded:
                return "unloaded";
            case container::read_error::out_of_range_play_frame:
                return "out_of_range_play_frame";
            case container::read_error::copy_failed:
                return "copy_failed";
        }
    }
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, std::size_t const count, url const &ch_url,
                                             operation_queue queue)
    : base(std::make_shared<impl>(format, count, ch_url, std::move(queue))) {
}

audio_circular_buffer::audio_circular_buffer(std::nullptr_t) : base(nullptr) {
}

void audio_circular_buffer::read_into_buffer(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read_into_buffer(out_buffer);
}
