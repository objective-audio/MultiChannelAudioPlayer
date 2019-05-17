//
//  yas_playing_numbers_file_tests.mm
//

#import <XCTest/XCTest.h>
#import <cpp_utils/yas_boolean.h>
#import <cpp_utils/yas_file_path.h>
#import <cpp_utils/yas_system_path_utils.h>
#import <playing/yas_playing_numbers_file.h>

using namespace yas;
using namespace yas::playing;

namespace yas::playing::numbers_file_test {
struct cpp {
    std::string const root_path =
        system_path_utils::directory_url(system_path_utils::dir::document).appending("root").path();
};
}

@interface yas_playing_numbers_file_tests : XCTestCase

@end

@implementation yas_playing_numbers_file_tests {
    numbers_file_test::cpp _cpp;
}

- (void)setUp {
}

- (void)tearDown {
}

- (void)test_numbers_file {
    auto const path = file_path{self->_cpp.root_path}.appending("numbers").string();

    numbers_file::event_map_t events{
        {0, proc::make_number_event(double(0.0))},   {1, proc::make_number_event(float(1.0))},
        {2, proc::make_number_event(int64_t(2))},    {3, proc::make_number_event(uint64_t(3))},
        {4, proc::make_number_event(int32_t(4))},    {5, proc::make_number_event(uint32_t(5))},
        {6, proc::make_number_event(int16_t(6))},    {7, proc::make_number_event(uint16_t(7))},
        {8, proc::make_number_event(int8_t(8))},     {9, proc::make_number_event(uint8_t(9))},
        {10, proc::make_number_event(boolean(true))}};

    auto write_result = numbers_file::write(path, events);

    XCTAssertTrue(write_result);
}

@end
