#!/bin/bash

#cleanups
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"

simg2img /build2/AOSP-11.0/out/target/product/phhgsi_arm_ab/system.img s.img
rm -Rf tmp
mkdir -p d tmp
mount -o loop,rw s.img d
(
cd d

cp init.environ.rc "$origin"/tmp

find -maxdepth 1 -not -name system -not -name . -not -name .. -exec rm -Rf '{}' +
mv system/* .
rmdir system

#cp "$origin/x86/libbinder-27.so" system_ext/apex/com.android.vndk.v27/lib/libbinder.so
#cp "$origin/x86/libhwbinder-27.so" system_ext/apex/com.android.vndk.v27/lib/libhwbinder.so
#xattr -w security.selinux u:object_r:system_lib_file:s0 system_ext/apex/com.android.vndk.v27/lib/libbinder.so system_ext/apex/com.android.vndk.v27/lib/libhwbinder.so
#
#cp "$origin/x86/libbinder-30.so" lib/libbinder.so
#cp "$origin/x86/libhwbinder-30.so" lib/libhwbinder.so
#xattr -w security.selinux u:object_r:system_lib_file:s0 lib/libbinder.so lib/libhwbinder.so
#
#cp "$origin/x86/libhidlbase.so" lib/libhidlbase.so
#xattr -w security.selinux u:object_r:system_lib_file:s0 lib/libhdilbase.so

rm -Rf system_ext/apex/com.android.vndk.v29 system_ext/apex/com.android.vndk.v28

sed -i \
    -e '/ro.radio.noril/d' \
    -e '/sys.usb.config/d' \
    -e '/ro.build.fingerprint/d' \
    -e '/persist.sys.theme/d' \
    -e '/ro.opengles.version/d' \
    -e '/ro.sf.lcd_density/d' \
    -e '/sys.usb.controller/d' \
    -e '/persist.dbg.volte_avail_ovr/d' \
    -e '/persist.dbg.wfc_avail_ovr/d' \
    -e '/persist.radio.multisim.config/d' \
    etc/selinux/plat_property_contexts

xattr -w security.selinux u:object_r:property_contexts_file:s0 etc/selinux/plat_property_contexts

sed -i \
    -e 's;Android/treble_x86_64_bvS/phhgsi_x86_64_ab:11/RP1A.200720.011/phh09150939:userdebug/test-keys;Android/treble_x86_64_bvS/phhgsi_x86_64_ab:11/RP1A.200720.011/phh:userdebug/test-keys;g' \
    build.prop
xattr -w security.selinux u:object_r:system_file:s0 etc/selinux/plat_property_contexts

cp "$origin"/files/apex-setup.rc etc/init/
xattr -w security.selinux u:object_r:system_file:s0 etc/init/apex-setup.rc

cp "$origin"/tmp/init.environ.rc etc/init/init-environ.rc
sed -i 's/on early-init/on init/g' etc/init/init-environ.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/init-environ.rc

sed -i \
    -e /@include/d \
    -e /newfstatat/d \
    -e s/MREMAP_MAYMOVE/1/g \
    etc/seccomp_policy/mediaextractor.policy \
    etc/seccomp_policy/mediacodec.policy \
    system_ext/apex/com.android.media/etc/seccomp_policy/mediaextractor.policy \
    system_ext/apex/com.android.media.swcodec/etc/seccomp_policy/mediaswcodec.policy
echo 'getdents64: 1' >> etc/seccomp_policy/mediaextractor.policy
echo 'getdents64: 1' >> system_ext/apex/com.android.media/etc/seccomp_policy/mediaextractor.policy
xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.media/etc/seccomp_policy/mediaextractor.policy system_ext/apex/com.android.media.swcodec/etc/seccomp_policy/mediaswcodec.policy
xattr -w security.selinux u:object_r:system_seccomp_policy_file:s0 etc/seccomp_policy/mediacodec.policy etc/seccomp_policy/mediaextractor.policy

#"lmkd" user and group don't exist
#"readproc" doesn't exist, use SYS_PTRACE instead
sed -i -E \
    -e '/user lmkd/d' \
    -e 's/group .*/group root/g' \
    -e 's/capabilities (.*)/capabilities \1 SYS_PTRACE/g' \
    etc/init/lmkd.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/lmkd.rc

sed -i -E \
    -e '/user/d' \
    -e '/group/d' \
    etc/init/credstore.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/credstore.rc

for lib in $(cd "$origin/vndk-27-arm32"; echo *.so);do
    cp "$origin/vndk-27-arm32/$lib" system_ext/apex/com.android.vndk.v27/lib/$lib
    xattr -w security.selinux u:object_r:system_lib_file:s0 system_ext/apex/com.android.vndk.v27/lib/$lib
    echo $lib >> system_ext/apex/com.android.vndk.v27/etc/vndkcore.libraries.27.txt
done
xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.vndk.v27/etc/vndkcore.libraries.27.txt

cp system_ext/apex/com.android.media.swcodec/etc/init.rc etc/init/media-swcodec.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/media-swcodec.rc

sed -i s/ro.iorapd.enable=true/ro.iorapd.enable=false/g etc/prop.default
xattr -w security.selinux u:object_r:system_file:s0 etc/prop.default

)
sleep 1


umount d

e2fsck -f -y s.img || true
resize2fs -M s.img
