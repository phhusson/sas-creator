#!/bin/bash

#cleanups
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"

[ ! -d vendor_vndk ] && git clone https://github.com/phhusson/vendor_vndk -b android-10.0

[ -z "$ANDROID_BUILD_TOP" ] && ANDROID_BUILD_TOP=/build2/AOSP-11.0/
simg2img "$ANDROID_BUILD_TOP"/out/target/product/phhgsi_arm64_ab/system.img s.img
rm -Rf tmp
mkdir -p d tmp
e2fsck -y -f s.img
resize2fs s.img 2500M
mount -o loop,rw s.img d
(
cd d
for vndk in 28 29;do
    for arch in 32 64;do
        d="$origin/vendor_vndk/vndk-${vndk}-arm${arch}"
        [ ! -d "$d" ] && continue
        for lib in $(cd "$d"; echo *);do
            p=lib
            [ "$arch" = 64 ] && p=lib64
            cp "$origin/vendor_vndk/vndk-${vndk}-arm${arch}/$lib" system/system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
            xattr -w security.selinux u:object_r:system_lib_file:s0 system/system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
            echo $lib >> system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
        done
        sort -u system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt > v
        mv -f v system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
        xattr -w security.selinux u:object_r:system_file:s0 system/system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
    done
done


)
sleep 1


umount d

e2fsck -f -y s.img || true
resize2fs -M s.img
