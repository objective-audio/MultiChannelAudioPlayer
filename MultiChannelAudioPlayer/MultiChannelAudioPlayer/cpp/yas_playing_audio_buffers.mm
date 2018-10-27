//
//  yas_playing_audio_buffers.cpp
//

#include "yas_playing_audio_buffers.h"

using namespace yas;
using namespace yas::playing;

struct audio_buffers::impl : base::impl {};

audio_buffers::audio_buffers() : base(std::make_shared<impl>()) {
}
