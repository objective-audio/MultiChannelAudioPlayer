//
//  yas_multi_track_audio_player.mm
//

#include "yas_multi_track_audio_player.h"

using namespace yas::multi_track;

struct audio_player::impl : base::impl {};

audio_player::audio_player() : base(std::make_shared<impl>()) {
}
