#!/bin/bash
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
ls -l "$K"
echo "fbprobe: $(strings -a "$K" | grep -c 'fbprobe')"
echo "P34:    $(strings -a "$K" | grep -c 'P34: ')"
echo "fbpaint: $(strings -a "$K" | grep -c 'painted the panel memory')"
echo "=== 构建脚本是否覆盖源文件 ==="
grep -n 'iokit/Kernel\|files/iokit\|MiniIOMobile\|cp -f' /mnt/d/桌面/star26-deps/scripts/build-k90-tree.sh | head -20
echo "=== 最近修改的 .o（前 15） ==="
find /root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837 -name '*.o' -newermt '2026-11-14 19:20' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -15
