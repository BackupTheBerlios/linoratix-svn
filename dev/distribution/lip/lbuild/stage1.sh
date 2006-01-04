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

./build_script.sh binutils.lbuild || ldie "Error building binutils"
./build_script.sh gcc3.lbuild || ldie "Error building gcc"
./build_script.sh distcc.lbuild || ldie "Error building distcc"
./build_script.sh linux-libc-headers.lbuild || ldie "Error building linux-libc-headers"
#./build_script.sh fakeroot.lbuild || ldie "Error building fakeroot"

# glibc kann nicht mit fakeroot gebaut werden
./build_script.sh glibc.lbuild || ldie "Error building glibc"



# linker pfad anpassen
script_dir=`pwd`

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

cd $script_dir

./build_script.sh tcl.lbuil
TCLPATH=/tmp/build/tcl/linoratix/build/tcl8.4.11 ./build_script.sh expect.lbuild

./build_script.sh expect.lbuild
./build_script.sh dejagnu.lbuild

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

./build_script.sh gcc3.lbuild || ldie "Error building gcc (Stage: ${STAGE})"
./build_script.sh binutils.lbuild || ldie "Error building binutils (Stage: ${STAGE})"
./build_script.sh gawk.lbuild || ldie "Error building gawk (Stage: ${STAGE})"
./build_script.sh coreutils.lbuild || ldie "Error building coreutils (Stage: ${STAGE})"
./build_script.sh bzip2.lbuild || ldie "Error building bzip2 (Stage: ${STAGE})"
./build_script.sh gzip.lbuild || ldie "Error building gzip (Stage: ${STAGE})"
./build_script.sh diffutils.lbuild || ldie "Error building diffutils (Stage: ${STAGE})"
./build_script.sh findutils.lbuild || ldie "Error building findutils (Stage: ${STAGE})"
./build_script.sh make.lbuild || ldie "Error building make (Stage: ${STAGE})"
./build_script.sh grep.lbuild || ldie "Error building grep (Stage: ${STAGE})"
./build_script.sh sed.lbuild || ldie "Error building sed (Stage: ${STAGE})"
./build_script.sh gettext.lbuild || ldie "Error building gettext (Stage: ${STAGE})"
./build_script.sh ncurses.lbuild || ldie "Error building ncurses (Stage: ${STAGE})"
./build_script.sh patch.lbuild || ldie "Error building patch (Stage: ${STAGE})"
./build_script.sh tar.lbuild || ldie "Error building tar (Stage: ${STAGE})"
./build_script.sh texinfo.lbuild || ldie "Error building texinfo (Stage: ${STAGE})"
./build_script.sh bash.lbuild || ldie "Error building bash (Stage: ${STAGE})"
./build_script.sh m4.lbuild || ldie "Error building m4 (Stage: ${STAGE})"
./build_script.sh util-linux.lbuild || ldie "Error building util-linux (Stage: ${STAGE})"
./build_script.sh perl.lbuild || ldie "Error building perl (Stage: ${STAGE})"

strip --strip-debug /tools/lib/*
strip --strip-unneeded /tools/{,s}bin/*

rm -rf /tools/{info,man}


echo
echo "Buildenv wurde erfolgreich gebaut!"
echo "Stage 1 wurde erreicht!"
echo

echo "1" > current_stage

export STAGE=2


