//
//  yas_playing_audio_coordinator.cpp
//

#include "yas_playing_audio_coordinator.h"

using namespace yas;
using namespace yas::playing;

struct audio_coordinator::impl : base::impl {
    url _root_url;

    impl(url &&root_url) : _root_url(std::move(root_url)) {
    }
};

audio_coordinator::audio_coordinator(url root_url) : base(std::make_shared<impl>(std::move(root_url))) {
}

audio_coordinator::audio_coordinator(std::nullptr_t) : base(nullptr) {
}
