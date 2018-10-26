//
//  yas_multi_track_url.h
//

#pragma once

#include "yas_base.h"
#include "yas_url.h"

namespace yas::multi_track {
struct url : base {
    class impl;

    url(yas::url const &root_url);
};
}  // namespace yas::multi_track
