#!/bin/bash
echo "=== 源码树当前状态 (annibale_adreno.c) ==="
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
ls -la "$F" "$F.s218-pre" 2>&1
md5sum "$F" "$F.s218-pre" 2>&1
echo "s218 调频符号是否还在源码里:"
grep -n "star_gpu_speed_tick\|annibale_gpu_speed\|annibale_gpu_temperature" "$F" | head -10
echo
echo "=== 编译出的内核二进制状态 ==="
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
ls -la "$K" 2>&1
md5sum "$K" 2>&1
echo
echo "=== 各镜像内核 md5 (s216/s217/s218) ==="
for p in s216parts s217parts s218parts; do
  D=/root/star26/baseline/$p
  if [ -d "$D" ]; then
    find "$D" -iname '*kernel*' -o -iname 'mach*' 2>/dev/null | head -3 | while read f; do printf '%-14s ' "$p"; md5sum "$f"; done
  fi
done
echo
echo "=== cmdline 现状 (s217) ==="
find /root/star26/baseline/s217parts -iname '*cmdline*' 2>/dev/null | head -3 | while read f; do echo "-- $f"; cat "$f"; echo; done
