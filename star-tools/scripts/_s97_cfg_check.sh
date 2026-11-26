#!/bin/bash
cd /root/star26/star-native || exit 1
K=BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "===== 1) all mac_* symbols count ====="
nm "$K" 2>/dev/null | grep -cE " _mac_|_mac_" 
nm "$K" 2>/dev/null | grep -E "_mac_" | head -10
echo
echo "===== 2) build dir listing ====="
ls -la BUILD/obj/RELEASE_ARM64_BCM2837/ | head -30
echo
echo "===== 3) find the config used ====="
find BUILD -maxdepth 3 -type f \( -name "*.config" -o -name "config*" \) | head -10
echo
echo "===== 4) grep CONFIG_MACF in build tree (any file) ====="
grep -rIl "CONFIG_MACF" BUILD 2>/dev/null | head -10
echo "--- and definition value:"
grep -rn "CONFIG_MACF" BUILD/obj/RELEASE_ARM64_BCM2837/* 2>/dev/null | head -10
echo
echo "===== 5) conf files locations ====="
ls bsd/conf/ | head; echo ---
grep -rn "CONFIG_MACF" bsd/conf/* 2>/dev/null | head -10
echo
echo "===== 6) which config does build-star-native.sh use? ====="
grep -n "conf\|CONF\|config\|TARGET" /mnt/d/桌面/star26-deps/scripts/build-star-native.sh | head -30
echo
echo "===== DONE ====="
