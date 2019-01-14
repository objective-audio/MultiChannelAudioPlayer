#!/bin/sh

clang-format -i -style=file `find ../MultiChannelAudioPlayer ../playing -type f \( -name *.h -o -name *.cpp -o -name *.hpp -o -name *.m -o -name *.mm \)`
