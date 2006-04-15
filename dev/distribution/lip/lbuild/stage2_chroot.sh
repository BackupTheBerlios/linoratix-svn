#!/bin/bash


export STAGE=2

echo "/lib" > /etc/ld.so.conf
echo "/usr/lib" >> /etc/ld.so.conf
echo "/usr/local/lib" >> /etc/ld.so.conf

echo "running ldconfig..."
ldconfig

cd /usr/ports/tools
./build_script.sh ../sqlite3.lbuild
./build_script.sh ../wget.lbuild
./build_script.sh ../linux-libc-headers.lbuild
./build_script.sh ../man-pages.lbuild
./build_script.sh ../glibc.lbuild

# hier fehlt noch 
cd /tmp/build/binutils/linoratix/build/binutils-build
make -C ld INSTALL=/tools/bin/install install
cd $OLDPWD
# das muss im binutils-build dir ausgefuehrt werden!!!

perl -pi -e 's@ /tools/lib/ld-linux.so.2@ /lib/ld-linux.so.2@g;' \
    -e 's@\*startfile_prefix_spec:\n@$_/usr/lib/ @g;' \
        `gcc --print-file specs`

# 
# test noch einbauen
# 
#echo 'main(){}' > dummy.c
#cc dummy.c
#readelf -l a.out | grep ': /lib'
### es muss [Requesting program interpreter: /lib/ld-linux.so.2]  rauskommen
# rm -v dummy.c a.out

############################

ldconfig
rm -rf /tmp/binutils /tmp/build/binutils
./build_script.sh ../binutils.lbuild
ldconfig

