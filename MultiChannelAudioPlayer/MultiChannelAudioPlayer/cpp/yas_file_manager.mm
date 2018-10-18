//
//  yas_file_manager.mm
//

#include "yas_file_manager.h"
#import <Foundation/Foundation.h>
#include "yas_cf_utils.h"

using namespace yas;

file_manager::create_dir_result_t file_manager::create_directory_if_not_exists(std::string const &path) {
    auto file_manager = [NSFileManager defaultManager];
    BOOL is_directory = NO;
    CFStringRef cf_path = to_cf_object(path);

    if (![file_manager fileExistsAtPath:(__bridge NSString *)cf_path isDirectory:&is_directory]) {
        NSError *error = nil;
        if (![file_manager createDirectoryAtPath:(__bridge NSString *)cf_path
                     withIntermediateDirectories:YES
                                      attributes:nil
                                           error:&error]) {
            return create_dir_result_t{create_dir_error::create_failed};
        }
    } else if (!is_directory) {
        return create_dir_result_t{create_dir_error::file_exists};
    }

    return create_dir_result_t{nullptr};
}

file_manager::exists_result_t file_manager::file_exists(std::string const &path) {
    auto file_manager = [NSFileManager defaultManager];
    BOOL is_directory = NO;
    CFStringRef cf_path = to_cf_object(path);

    if ([file_manager fileExistsAtPath:(__bridge NSString *)cf_path isDirectory:&is_directory]) {
        if (is_directory) {
            return exists_result_t{kind::directory};
        } else {
            return exists_result_t{kind::file};
        }
    } else {
        return exists_result_t{nullptr};
    }
}

std::string yas::to_string(file_manager::create_dir_error const &error) {
    switch (error) {
        case file_manager::create_dir_error::create_failed:
            return "create_failed";
        case file_manager::create_dir_error::file_exists:
            return "file_exists";
    }
}
