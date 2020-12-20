#!/bin/bash

#Usage:
#bash lite-adapter.sh <32|64> [/path/to/system/image]

#cleanups
umount d

set -ex

origin="$(readlink -f -- "$0")"
origin="$(dirname "$origin")"

if [ -f "$1" ];then
    srcFile="$1"
fi

if [ ! -f "$srcFile" ];then
	echo "Usage: sudo bash securize.sh <32|64> [/path/to/system.img]"
	exit 1
fi

"$origin"/simg2img "$srcFile" s-secure.img || cp "$srcFile" s-secure.img

rm -Rf tmp
mkdir -p d tmp
e2fsck -y -f s-secure.img
resize2fs s-secure.img 3500M
e2fsck -E unshare_blocks -y -f s-secure.img
mount -o loop,rw s-secure.img d

touch d/system/phh/secure
rm d/system/xbin/su
rm d/system/bin/phh-su
rm d/system/etc/init/su.rc
rm d/system/bin/phh-securize.sh
rm -Rf d/system/{app,priv-app}/me.phh.superuser/

sleep 1

umount d

e2fsck -f -y s-secure.img || true
resize2fs -M s-secure.img
