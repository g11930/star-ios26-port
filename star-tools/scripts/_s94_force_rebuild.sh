#!/bin/bash
# 强制全新链接：移除 stale .a 归档 + 内核产物，touch 已改源码，重新 make。
set -e
T=/root/star26/star-native
OBJ=$T/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== 1) remove stale archive + kernel artifacts ==="
rm -f "$OBJ/mach.release.bcm2837.link/mach.release.bcm2837.a"
rm -f "$OBJ/mach.release.bcm2837" "$OBJ/mach.release.bcm2837.unstripped" \
      "$OBJ/mach.release.bcm2837.unstripped.noctf" "$OBJ/mach.release.bcm2837.ctf"
echo "removed"

echo "=== 2) force-touch changed sources ==="
touch "$T/bsd/kern/kern_cs.c" "$T/bsd/kern/mach_loader.c" "$T/iokit/Kernel/MiniFramebufferUserClient.inc"
stat -c '%y %n' "$T/bsd/kern/kern_cs.c" "$T/bsd/kern/mach_loader.c"

echo "=== 3) rebuild ==="
bash /mnt/d/桌面/star26-deps/scripts/build-star-native.sh 2>&1 | tail -12

echo "=== 4) verify patch in final kernel ==="
B=$OBJ/mach.release.bcm2837
stat -c '%s bytes %y' "$B"
echo -n "star_cs_keep_valid: "; strings -a "$B" | grep -c "star_cs_keep_valid"
echo -n "star_cs_probe (want 0): "; strings -a "$B" | grep -c "star_cs_probe" || true
echo -n "CS_INITPAGE_BAD (want 0): "; strings -a "$B" | grep -c "CS_INITPAGE_BAD" || true
