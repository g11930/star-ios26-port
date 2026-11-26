#!/bin/bash
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
F=/root/star26/star-native/osfmk/arm64/sleh.c
echo "=== sleh.c 时间戳 + git 状态 ==="
ls -la "$F"
cd /root/star26/star-native && git log --oneline -5 -- osfmk/arm64/sleh.c 2>/dev/null
echo "working tree sleh.c diff?:"; cd /root/star26/star-native && git status --short osfmk/arm64/sleh.c 2>/dev/null
echo
echo "=== 三内核 PAC 字符串对比 (boot-arg 字符串是硬证据) ==="
for kv in "s208:/root/star26/baseline/s208parts/kernel" "s217:/root/star26/baseline/s217parts/kernel" "s218BUILD:/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"; do
  n=${kv%%:*}; k=${kv#*:}
  echo "--- $n ($(md5sum "$k" 2>/dev/null | cut -c1-8)) ---"
  printf '  pac_patch       : '; strings -a "$k" 2>/dev/null | grep -c '^pac_patch$'
  printf '  pac_patch_fips  : '; strings -a "$k" 2>/dev/null | grep -c 'pac_patch_fips'
  printf '  software PAuth  : '; strings -a "$k" 2>/dev/null | grep -c 'software PAuth active'
  printf '  cc_fips needle  : '; strings -a "$k" 2>/dev/null | grep -c 'cc_fips'
  printf '  PAC category    : '; strings -a "$k" 2>/dev/null | grep -c 'CATEGORY MASK'
done
echo
echo "=== nm 符号 (s217 内核) ==="
K=/root/star26/baseline/s217parts/kernel
nm "$K" 2>/dev/null | grep -iE 'pac_patch|pac_emu|cc_fips' | head -20
