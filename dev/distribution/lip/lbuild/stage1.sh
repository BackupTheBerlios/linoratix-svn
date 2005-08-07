#!/bin/sh

#
# script um stage 1 zu bauen
#

export BUILD_BUILD_ENV=1 

fakeroot ./build_script.sh binutils.lbuild
fakeroot ./build_script.sh gcc3.lbuild
fakeroot ./build_script.sh linux-libc-headers.lbuild

./build_script.sh glibc.lbuild
