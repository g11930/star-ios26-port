#!/bin/bash
OBJ=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837
echo "=== obj 目录里的内核文件 ==="
ls -la "$OBJ"/mach.release.bcm2837* 2>/dev/null
echo
echo "=== 找 .noctf / unstripped ==="
find "$OBJ" -maxdepth 1 -type f \( -name '*noctf*' -o -name '*unstrip*' -o -name 'mach.release*' \) 2>/dev/null
echo
echo "=== 在各个可能的二进制上 nm 核验 ==="
for K in "$OBJ/mach.release.bcm2837.noctf" "$OBJ/mach.release.bcm2837" "$OBJ/mach.noctf" "$OBJ/mach.release"; do
  if [ -f "$K" ]; then
    echo "--- $K ($(stat -c%s "$K") bytes) ---"
    nm "$K" 2>/dev/null | grep -iE 'star_cs_keep_valid|s212' || echo "  (no match)"
  fi
done
