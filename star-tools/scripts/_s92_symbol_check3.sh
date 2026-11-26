#!/bin/bash
# s92: check minimac object compiled in + mac_policy_register presence in linked kernel
O=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.o
# find a working nm: xnu build uses ctfctoolchain; try cross nm variants
for T in nm llvm-nm aarch64-linux-gnu-nm /usr/bin/nm; do
  command -v $T >/dev/null 2>&1 && { echo "using $T"; NM=$T; break; }
done
${NM:-nm} -g "$O" 2>&1 | head -5
echo "===D-FILE-DEPS==="
head -3 /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.d
echo "===MACF-OPTION-CHECK==="
grep -rn "CONFIG_MACF" /root/star26/star-native/bsd/conf/options 2>/dev/null | head -3
grep -rn "MACF" /root/star26/star-native/bsd/conf/options 2>/dev/null | head -5
echo "===CONFIG-FILE==="
grep -rn "MACF" /root/star26/star-native/config/ 2>/dev/null | head -10
