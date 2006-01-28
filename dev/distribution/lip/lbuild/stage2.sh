#!/bin/sh

#
# script fuer stage 2
#

export BUILD_BUILD_ENV=1
export STAGE=2

mkdir -pv /tools/{proc,sys}
mount -vt proc proc /tools/proc
mount -vt sysfs sysfs /tools/sys

mount -vft tmpfs tmpfs /tools/dev
mount -vft tmpfs tmpfs /tools/dev/shm
mount -vft devpts -o gid=4,mode=620 devpts /tools/dev/pts

cd /tools
ln -s . tools
cd $OLDPWD

chroot "/tools" /tools/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h

