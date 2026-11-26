#!/bin/bash
# s92: verify CONFIG_MACF in the actual build config used
echo "===MACHINE-CONFIG==="
find /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/config -name '*.conf' 2>/dev/null | head -5
grep -rn "MACF\|CONFIG_MAC" /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/config/ 2>/dev/null | head -10
echo "===BSD-CONF==="
find /root/star26/star-native/BUILD/obj -name 'bsd.*conf*' -o -name '*.conf' 2>/dev/null | head -8
echo "===META-FEATURES==="
grep -n 'MACF' /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/meta_features.h 2>/dev/null | head -5
grep -rn 'MACF' /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/ 2>/dev/null --include='*.h' | head -8
