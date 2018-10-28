//
//  yas_playing_audio_channel_buffer.mm
//

#include "yas_playing_audio_circular_buffer.h"
#include <mutex>
#include "yas_audio_format.h"
#include "yas_fast_each.h"
#include "yas_operation.h"

using namespace yas;
using namespace yas::playing;

struct audio_circular_buffer::impl : base::impl {
    struct container {
        enum state {
            unloaded,
            loading,
            loaded,
        };

        audio::pcm_buffer buffer;
        int64_t begin_frame;
        state state = state::unloaded;

        container(audio::pcm_buffer &&buffer) : buffer(std::move(buffer)) {
        }

        bool contains(int64_t const frame) {
            return begin_frame <= frame && frame < (begin_frame + buffer.frame_length());
        }
    };

    using container_ptr = std::shared_ptr<container>;

    impl(audio::format const &format, uint32_t const count) {
        auto each = make_fast_each(count);
        while (yas_each_next(each)) {
            auto ptr =
                std::make_shared<container>(audio::pcm_buffer{format, static_cast<uint32_t>(format.sample_rate())});
            this->_containers.emplace_back(std::move(ptr));
        }
    }

    void read(audio::pcm_buffer &out_buffer) {
        uint32_t remain = out_buffer.frame_length();

        while (remain > 0) {
#warning todo bufferをロックして読み出す
            if (auto lock = std::unique_lock<std::recursive_mutex>(this->_read_mutex)) {
                int64_t current_frame = this->_current_frame;
            }
        }
    }

    container_ptr &current_container() {
        for (auto &container : this->_containers) {
            if (container->contains(this->_current_frame)) {
                return container;
            }
        }
        static container_ptr null_container = nullptr;
        return null_container;
    }

   private:
    std::vector<container_ptr> _containers;
    operation_queue _queue;
    int64_t _current_frame;
    std::recursive_mutex _read_mutex;
};

audio_circular_buffer::audio_circular_buffer(audio::format const &format, uint32_t const count)
    : base(std::make_shared<impl>(format, count)) {
}

void audio_circular_buffer::read(audio::pcm_buffer &out_buffer) {
    impl_ptr<impl>()->read(out_buffer);
}
