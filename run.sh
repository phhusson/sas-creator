#!/bin/bash

#cleanups
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"

simg2img system.img s.img
rm -Rf tmp
mkdir -p d tmp
mount -o loop,rw s.img d
(
cd d

cp init.environ.rc "$origin"/tmp

find -maxdepth 1 -not -name system -not -name . -not -name .. -exec rm -Rf '{}' +
mv system/* .
rmdir system

sed -i \
    -e '/ro.radio.noril/d' \
    -e '/sys.usb.config/d' \
    -e '/ro.build.fingerprint/d' \
    -e '/persist.sys.theme/d' \
    etc/selinux/plat_property_contexts

xattr -w security.selinux u:object_r:property_contexts_file:s0 etc/selinux/plat_property_contexts

cp "$origin"/files/apex-setup.rc etc/init/
xattr -w security.selinux u:object_r:system_file:s0 etc/init/apex-setup.rc

cp "$origin"/tmp/init.environ.rc etc/init/init-environ.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/init-environ.rc

)
sleep 1


umount d
