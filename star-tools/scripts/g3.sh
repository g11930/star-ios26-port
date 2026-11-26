#!/bin/bash
cd /root/star26/star-native || exit 1
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s33 s32 "" panic_on_crash_disabled=1 2>&1
