#!/bin/bash
cd /root/star26/star-native || exit 1
K=BUILD/obj/RELEASE_ARM64_BCM2837
echo "===== A) kern_cs.c 1860-1935 (entitlements getter) ====="
sed -n '1860,1935p' bsd/kern/kern_cs.c
echo
echo "===== B) kern_cs.c 500-560 (blob invalidate) ====="
sed -n '500,560p' bsd/kern/kern_cs.c
echo
echo "===== C) CS_PLATFORM_BINARY set sites ====="
grep -rn "CS_PLATFORM_BINARY" --include=*.c --include=*.h . 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "===== D) ip_csflags / load_result.csflags assignments ====="
grep -rn "load_result.csflags\|ip_csflags =\|ip_csflags |=" bsd/kern/*.c | grep -v "\.bak" | head -20
echo
echo "===== E) is MACF code in the build/link? ====="
grep -c "security/" $K/link.filelist
grep -n "mac_vfs\|mac_framework\|mac_policy" $K/link.filelist | head -10
echo "--- source files gated by CONFIG_MACF in bsd/conf/files:"
grep -n "CONFIG_MACF" bsd/conf/files | head -20
echo
echo "===== F) ls link.filelist security entries ====="
strings $K/mach.release.bcm2837 | grep -c "mac_policy_register"
echo
echo "===== DONE ====="
