#!/bin/bash

#cleanups
umount d

set -ex

simg2img system.img s.img
mkdir -p d
mount -o loop,rw s.img d
(
cd d
find -maxdepth 1 -not -name system -not -name . -not -name .. -exec rm -Rf '{}' +
mv system/* .
rmdir system
)
sleep 1


umount d
