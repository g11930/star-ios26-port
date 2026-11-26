#!/bin/bash
# s73 runner: repack from s72 parts, kernel unchanged, boot-arg -show_pointers=1
# added to disable printf pointer redaction (printf.c doprnt_hide_pointers).
cd /root/star26/star-native || exit 1
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s73 s72 "" -show_pointers=1 2>&1 | tail -8
echo "---- kernel md5 (must equal s72: bab98b9cea5653f1ac2e57e6d1b6ef60) ----"
md5sum /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
