//
//  yas_audio_circular_buffer_chain_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/cpp_utils.h>
#import <playing/yas_playing_audio_circular_buffer.h>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::audio_circular_buffer_chain_test {
struct cpp {
    task_queue queue{nullptr};
    sample_rate_t const sample_rate = 3;
    channel_index_t const ch_idx = 0;
    std::size_t const ch_count = 1;
    url const root_url = system_path_utils::directory_url(system_path_utils::dir::document).appending("root");
    audio::format const format{audio::format::args{.sample_rate = static_cast<double>(this->sample_rate),
                                                   .channel_count = 1,
                                                   .pcm_format = audio::pcm_format::int16,
                                                   .interleaved = false}};
};
}

@interface yas_audio_circular_buffer_chain_tests : XCTestCase

@end

@implementation yas_audio_circular_buffer_chain_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_states_chain {
}

@end
