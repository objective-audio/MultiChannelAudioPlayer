//
//  yas_audio_circuler_buffer_tests.mm
//

#import <XCTest/XCTest.h>
#import "yas_audio_format.h"
#import "yas_playing_audio_circular_buffer.h"

using namespace yas;
using namespace yas::playing;

@interface yas_audio_circuler_buffer_tests : XCTestCase

@end

@implementation yas_audio_circuler_buffer_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_make {
    operation_queue queue;

    audio::format format{audio::format::args{
        .sample_rate = 48000.0, .channel_count = 1, .pcm_format = audio::pcm_format::int16, .interleaved = false}};
}

@end
