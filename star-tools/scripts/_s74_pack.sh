#!/bin/bash
# s74 runner: pack from s73 parts (keeps -show_pointers=1), new kernel with
# the syscall-decode probe.
cd /root/star26/star-native || exit 1
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s74 s73 "" 2>&1 | tail -8
echo "---- kernel md5 ----"
md5sum /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
