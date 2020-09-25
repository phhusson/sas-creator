#!/bin/bash

#cleanups
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"

targetArch=64
[ "$1" == 32 ] && targetArch=32

if [ "$targetArch" == 32 ];then
    simg2img /build2/AOSP-11.0/out/target/product/phhgsi_arm_ab/system.img s.img
else
    simg2img /build2/AOSP-11.0/out/target/product/phhgsi_arm64_ab/system.img s.img
fi
rm -Rf tmp
mkdir -p d tmp
e2fsck -f s.img
resize2fs s.img 2500M
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
    -e /persist.dbg.vt_avail_ovr/d \
    -e /ro.build.description/d \
    -e /ro.build.display.id/d \
    -e /ro.build.version.base_os/d \
    -e /ro.com.android.dataroaming/d \
    -e /ro.telephony.default_network/d \
    -e /ro.vendor.build.fingerprint/d \
    etc/selinux/plat_property_contexts

xattr -w security.selinux u:object_r:property_contexts_file:s0 etc/selinux/plat_property_contexts

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
echo 'rt_sigprocmask: 1' >> etc/seccomp_policy/mediaextractor.policy
echo 'rt_sigprocmask: 1' >> system_ext/apex/com.android.media/etc/seccomp_policy/mediaextractor.policy
echo 'rt_sigprocmask: 1' >> etc/seccomp_policy/mediacodec.policy
xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.media/etc/seccomp_policy/mediaextractor.policy system_ext/apex/com.android.media.swcodec/etc/seccomp_policy/mediaswcodec.policy
xattr -w security.selinux u:object_r:system_seccomp_policy_file:s0 etc/seccomp_policy/mediacodec.policy etc/seccomp_policy/mediaextractor.policy etc/seccomp_policy/mediacodec.policy

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

#for lib in $(cd "$origin/vndk-27-arm32"; echo *.so);do
#    cp "$origin/vndk-27-arm32/$lib" system_ext/apex/com.android.vndk.v27/lib/$lib
#    xattr -w security.selinux u:object_r:system_lib_file:s0 system_ext/apex/com.android.vndk.v27/lib/$lib
#    echo $lib >> system_ext/apex/com.android.vndk.v27/etc/vndkcore.libraries.27.txt
#done
#xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.vndk.v27/etc/vndkcore.libraries.27.txt

cp system_ext/apex/com.android.media.swcodec/etc/init.rc etc/init/media-swcodec.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/media-swcodec.rc

sed -i s/ro.iorapd.enable=true/ro.iorapd.enable=false/g etc/prop.default
xattr -w security.selinux u:object_r:system_file:s0 etc/prop.default

cp -R system_ext/apex/com.android.vndk.v27 system_ext/apex/com.android.vndk.v26
for i in vndkcore llndk vndkprivate vndksp;do
    mv system_ext/apex/com.android.vndk.v26/etc/${i}.libraries.27.txt system_ext/apex/com.android.vndk.v26/etc/${i}.libraries.26.txt
done
find system_ext/apex/com.android.vndk.v26 -exec xattr -w security.selinux u:object_r:system_file:s0 '{}' \;

vndk=26
archs="64 32"
if [ "$targetArch" == 32 ];then
    archs=32
fi
for arch in $archs;do
    for lib in $(cd "$origin/vendor_vndk/vndk-sp-${vndk}-arm${arch}"; echo *);do
        #TODO: handle "hw"
        [ ! -f "$origin/vendor_vndk/vndk-sp-${vndk}-arm${arch}"/$lib ] && continue
        p=lib
        [ "$arch" = 64 ] && p=lib64
        cp "$origin/vendor_vndk/vndk-sp-${vndk}-arm${arch}/$lib" system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
        xattr -w security.selinux u:object_r:system_lib_file:s0 system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
        echo $lib >> system_ext/apex/com.android.vndk.v${vndk}/etc/vndksp.libraries.${vndk}.txt
    done
    sort -u system_ext/apex/com.android.vndk.v${vndk}/etc/vndksp.libraries.${vndk}.txt > v
    mv -f v system_ext/apex/com.android.vndk.v${vndk}/etc/vndksp.libraries.${vndk}.txt
    xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.vndk.v${vndk}/etc/vndksp.libraries.${vndk}.txt
done

for vndk in 27 26;do
    archs="64 32"
    if [ "$targetArch" == 32 ];then
        archs="32 32-binder32"
    fi
    for arch in $archs;do
        t="$origin/vendor_vndk/vndk-${vndk}-arm${arch}"
        [ -d "$t" ] && for lib in $(cd "$origin/vendor_vndk/vndk-${vndk}-arm${arch}"; echo *);do
            p=lib
            [ "$arch" = 64 ] && p=lib64
            cp "$origin/vendor_vndk/vndk-${vndk}-arm${arch}/$lib" system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
            xattr -w security.selinux u:object_r:system_lib_file:s0 system_ext/apex/com.android.vndk.v${vndk}/${p}/$lib
            echo $lib >> system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
        done
        sort -u system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt > v
        mv -f v system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
        xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.vndk.v${vndk}/etc/vndkcore.libraries.${vndk}.txt
    done
done

sed -i 's/readproc//g' etc/init/llkd-debuggable.rc etc/init/llkd.rc
xattr -w security.selinux u:object_r:sepolicy_file:s0 etc/init/llkd-debuggable.rc etc/init/llkd.rc


sed -i 's/v27/v26/g' system_ext/apex/com.android.vndk.v26/apex_manifest.pb
xattr -w security.selinux u:object_r:system_file:s0 system_ext/apex/com.android.vndk.v26/apex_manifest.pb

echo -e '\nsetenforce 0\n' >> bin/rw-system.sh
xattr -w security.selinux u:object_r:phhsu_exec:s0 bin/rw-system.sh

sed -E -i 's/(.*allowx adbd functionfs .*0x6782)/\1 0x67e7/g' etc/selinux/plat_sepolicy.cil
xattr -w security.selinux u:object_r:sepolicy_file:s0 etc/selinux/plat_sepolicy.cil

sed -E -i 's/\+passcred//g' etc/init/logd.rc
sed -E -i 's/\+passcred//g' etc/init/lmkd.rc
sed -E -i 's/reserved_disk//g' etc/init/vold.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/vold.rc etc/init/logd.rc etc/init/lmkd.rc

sed -E -i /rlimit/d etc/init/bpfloader.rc etc/init/cameraserver.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/bpfloader.rc etc/init/cameraserver.rc

sed -i -e s/readproc//g -e s/reserved_disk//g etc/init/hw/init.zygote64.rc etc/init/hw/init.zygote64_32.rc etc/init/hw/init.zygote32_64.rc etc/init/hw/init.zygote32.rc
xattr -w security.selinux u:object_r:system_file:s0 etc/init/hw/init.zygote64.rc etc/init/hw/init.zygote64_32.rc etc/init/hw/init.zygote32_64.rc etc/init/hw/init.zygote32.rc

mkdir -p lib/vndk-sp-26
ln -s /apex/com.android.vndk.v26/lib/hw lib/vndk-sp-26/hw
xattr -sw security.selinux u:object_r:system_lib_file:s0 lib/vndk-sp-26/hw

)
sleep 1

umount d

e2fsck -f -y s.img || true
resize2fs -M s.img
