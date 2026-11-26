#!/bin/bash
cd /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837 || exit 1
OD=/usr/bin/llvm-objdump
O=osfmk/RELEASE/sleh.o

echo "=== [1] new kernel md5 ==="
md5sum mach.release.bcm2837 | cut -d' ' -f1

echo "=== [2] ret-rewrite constant 0xd65f03c0 occurrences in sleh.o ==="
$OD -d "$O" 2>/dev/null | grep -c 'd65f03c0'

echo "=== [3] nop constant 0xd503201f occurrences ==="
$OD -d "$O" 2>/dev/null | grep -c 'd503201f'

echo "=== [4] disasm around RET rewrite: look for mask/0xf and 0x2 gate ==="
$OD -d "$O" 2>/dev/null > /tmp/sleh.dis
LINE=$(grep -n 'd65f03c0' /tmp/sleh.dis | head -1 | cut -d: -f1)
echo "first d65f03c0 at disasm line: $LINE"
if [ -n "$LINE" ]; then
  START=$((LINE-28)); [ "$START" -lt 1 ] && START=1
  END=$((LINE+8))
  sed -n "${START},${END}p" /tmp/sleh.dis
fi

echo "=== [5] search immediate 0xf mask pattern (and x? , #0xf) near pac code ==="
grep -nE '#0xf\b|#15\b' /tmp/sleh.dis | head -20
