//
//  yas_playing_audio_coordinator.cpp
//

#include "yas_playing_audio_coordinator.h"

using namespace yas;
using namespace yas::playing;

struct audio_coordinator::impl : base::impl {};

audio_coordinator::audio_coordinator() : base(std::make_shared<impl>()) {
}

audio_coordinator::audio_coordinator(std::nullptr_t) : base(nullptr) {
}
