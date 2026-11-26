#!/bin/bash
# s72 runner: pack boot.img from s71 parts with the new kernel (no checkpoint).
cd /root/star26/star-native || exit 1
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s72 s71 "" 2>&1 | tail -12
echo "---- locate image ----"
ls -l /root/star26/s72/ 2>/dev/null | head -12
echo "---- kernel md5 ----"
md5sum /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
