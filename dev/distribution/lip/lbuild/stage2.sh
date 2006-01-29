#!/bin/sh

#
# script fuer stage 2
#

export BUILD_BUILD_ENV=0
export STAGE=2

mkdir -pv /tools/{proc,sys,dev}
mount -vt proc proc /tools/proc
mount -vt sysfs sysfs /tools/sys

mount -vft tmpfs tmpfs /tools/dev
mount -vft tmpfs tmpfs /tools/dev/shm
mount -vft devpts -o gid=4,mode=620 devpts /tools/dev/pts

cd /tools
ln -s . tools
cd $OLDPWD

mkdir -p /tools/root

echo "#!/bin/bash" > /tools/stage2.sh
echo "set +h" >> /tools/stage2.sh
echo "echo Welcome to STAGE 2" >> /tools/stage2.sh

chmod 700 /tools/stage2.sh

chroot "/tools" /tools/bin/env -i \
    HOME=/root TERM="$TERM" PS1='\u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/stage2.sh



#umount /tools/proc
#umount /tools/sys
#umount /tools/dev/*
#umount /tools/dev
