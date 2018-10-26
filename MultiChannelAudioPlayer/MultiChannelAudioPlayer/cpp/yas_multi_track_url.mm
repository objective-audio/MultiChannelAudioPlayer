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
