//
//  yas_multi_track_url.mm
//

#include "yas_multi_track_url.h"

using namespace yas;

struct multi_track::url::impl : base::impl {
    yas::url _root_url;

    impl(yas::url const &root_url) : _root_url(root_url) {
    }
};

multi_track::url::url(yas::url const &root_url) : base(std::make_shared<impl>(root_url)) {
}

yas::url multi_track::url::track_url(uint32_t const trk_idx) {
    yas::url const &root_url = impl_ptr<impl>()->_root_url;
    return root_url.appending(std::to_string(trk_idx));
}

yas::url multi_track::url::file_url(uint32_t const trk_idx, int64_t const file_idx) {
    yas::url const trk_url = this->track_url(trk_idx);
    return trk_url.appending(std::to_string(file_idx) + ".caf");
}
