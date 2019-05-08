//
//  yas_playing_audio_utils_tests.mm
//

#import <XCTest/XCTest.h>
#import <playing/yas_playing_audio_utils.h>

using namespace yas;
using namespace yas::playing;
using namespace yas::playing::audio_utils;

@interface yas_playing_audio_utils_tests : XCTestCase

@end

@implementation yas_playing_audio_utils_tests

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_processing_info_1 {
    {
        // ファイルの終わりに隣接しない
        processing_info info{0, 2, 3};

        XCTAssertEqual(info.length, 2);
        XCTAssertFalse(info.next_frag_idx);
    }

    {
        // ファイルの終わりに隣接する（1個目の前）
        processing_info info{1, 3, 3};

        XCTAssertEqual(info.length, 2);
        XCTAssertTrue(info.next_frag_idx);
        XCTAssertEqual(*info.next_frag_idx, 1);
    }

    {
        // ファイルの終わりに隣接する（2個目の前）
        processing_info info{3, 6, 3};

        XCTAssertEqual(info.length, 3);
        XCTAssertTrue(info.next_frag_idx);
        XCTAssertEqual(*info.next_frag_idx, 2);
    }

    {
        // ファイルの終わりに隣接する（0個目の前）
        processing_info info{-3, 0, 3};

        XCTAssertEqual(info.length, 3);
        XCTAssertTrue(info.next_frag_idx);
        XCTAssertEqual(*info.next_frag_idx, 0);
    }

    {
        // ファイルの終わりに隣接する（-1個目の前）
        processing_info info{-6, -3, 3};

        XCTAssertEqual(info.length, 3);
        XCTAssertTrue(info.next_frag_idx);
        XCTAssertEqual(*info.next_frag_idx, -1);
    }

    {
        // ファイルの境界をまたぐ
        processing_info info{2, 4, 3};

        XCTAssertEqual(info.length, 1);
        XCTAssertTrue(info.next_frag_idx);
        XCTAssertEqual(*info.next_frag_idx, 1);
    }
}

@end
