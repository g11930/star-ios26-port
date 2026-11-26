#!/bin/bash
cd /root/star26/star-native || exit 1
K=BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "===== 1) MACF symbols in kernel binary ====="
nm "$K" 2>/dev/null | grep -E "_mac_vnode_check_signature|_mac_policy_register|_mac_policy_list|_mac_policy_count|_mac_vnode_check_exec" | head -20
echo
echo "===== 2) generated config: MACF? ====="
find BUILD -name "*.config" -o -name "config.h" 2>/dev/null | head -3
grep -rn "CONFIG_MACF" BUILD/obj/RELEASE_ARM64_BCM2837/*.config BUILD/obj/RELEASE_ARM64_BCM2837/*.h 2>/dev/null | head -10
echo "--- source conf files:"
grep -rn "CONFIG_MACF" bsd/conf/conf_files/RELEASE_ARM64_BCM2837 2>/dev/null | head
ls bsd/conf/conf_files/ 2>/dev/null | head
echo
echo "===== 3) mac_policy_list symbol presence + section ====="
nm -m "$K" 2>/dev/null | grep -E "mac_policy|mac_policy_count" | head -20
echo
echo "===== 4) kern_cs.c 180-360 (valid clearing + guard) ====="
sed -n '180,360p' bsd/kern/kern_cs.c
echo
echo "===== DONE ====="
