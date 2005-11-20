#!/bin/sh

#
# script um stage 0 und 1 zu bauen
#

rm -f current_stage

export BUILD_BUILD_ENV=1 
export STAGE=0

set +h
umask 022
	
export PATH=/tools/bin:$PATH
export LC_ALL=POSIX

. ./functions.sh

fakeroot ./build_script.sh binutils.lbuild || ldie "Error building binutils"
fakeroot ./build_script.sh gcc3.lbuild || ldie "Error building gcc"
fakeroot ./build_script.sh distcc.lbuild || ldie "Error building distcc"
fakeroot ./build_script.sh linux-libc-headers.lbuild || ldie "Error building linux-libc-headers"
fakeroot ./build_script.sh fakeroot.lbuild || ldie "Error building fakeroot"

# glibc kann nicht mit fakeroot gebaut werden
./build_script.sh glibc.lbuild || ldie "Error building glibc"



# linker pfad anpassen
cd /tmp/build/binutils/linoratix/build/binutils-build
make -C ld install

SPECFILE=`gcc --print-file specs` &&
sed 's@ /lib/ld-linux.so.2@ /tools/lib/ld-linux.so.2@g' \
    $SPECFILE > tempspecfile &&
mv -f tempspecfile $SPECFILE &&
unset SPECFILE

rm -f /tools/lib/gcc/*/*/include/{pthread.h,bits/sigthread.h}

# ueberpruefen ob das env auch richtig kompiliert
echo 'main(){}' > test.c
cc test.c
readelf -l a.out | grep ': /tools'

if [ "$?" != "0" ]; then
	echo "Fehler im Buildenv!!"
	exit 1
fi

rm test.c a.out

fakeroot ./build_script.sh tcl.lbuil
TCLPATH=/tmp/build/tcl/linoratix/build/tcl8.4.11 fakeroot ./build_script.sh expect.lbuild

fakeroot ./build_script.sh expect.lbuild
fakeroot ./build_script.sh dejagnu.lbuild

echo
echo "Buildenv wurde erfolgreich gebaut!"
echo "Stage 0 wurde erreicht!"
echo

echo "0" > current_stage

export STAGE=1

rm -rf /tmp/build/gcc3/linoratix/build/gcc-build
rm -rf /tmp/build/gcc3/linoratix/build/gcc-3.4.3
rm -rf /tmp/build/binutils/linoratix/build/binutils-2.15.94.0.2.2
rm -rf /tmp/build/binutils/linoratix/build/binutils-build

fakeroot ./build_script.sh gcc3.lbuild || ldie "Error building gcc (Stage: ${STAGE})"
fakeroot ./build_script.sh binutils.lbuild || ldie "Error building binutils (Stage: ${STAGE})"

