#!/bin/bash
# s212: 只重编译内核（mach_loader.c CS_VALID 保护），不打包。
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh > /tmp/s212_build.log 2>&1
rc=$?
echo "BUILD_EXIT=$rc"
echo "errors: $(grep -c 'error:' /tmp/s212_build.log)"
grep -E 'error:' /tmp/s212_build.log | head -8
echo "--- tail ---"
tail -4 /tmp/s212_build.log
echo "--- new kernel md5 ---"
md5sum /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
