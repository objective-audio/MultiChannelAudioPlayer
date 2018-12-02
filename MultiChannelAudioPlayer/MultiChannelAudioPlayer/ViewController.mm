//
//  ViewController.m
//

#import "ViewController.h"
#import "yas_playing_audio.h"
#import "yas_system_url_utils.h"

using namespace yas;
using namespace yas::playing;

@interface ViewController ()

@end

namespace yas::playing::sample {
struct view_controller_cpp {
    url root_url{system_url_utils::directory_url(system_url_utils::dir::document).appending("sample")};
    operation_queue queue;
    audio_renderer renderer;
    audio_player player{this->renderer.renderable(), this->root_url, this->queue};
};
}

@implementation ViewController {
    sample::view_controller_cpp _cpp;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)start:(UIButton *)sender {
}

- (IBAction)stop:(UIButton *)sender {
}

@end
