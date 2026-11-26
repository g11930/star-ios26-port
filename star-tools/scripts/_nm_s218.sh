#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NOCTF=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.noctf
NM=/root/xnu26-test/bin/llvm-nm
echo "=== kernel md5 / size ==="
md5sum "$K"; stat -c%s "$K"
echo "=== find unstripped .noctf ==="
ls -la "$NOCTF" 2>/dev/null || find /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837 -maxdepth 1 -name "*.noctf" -o -name "*unstrip*" 2>/dev/null | head
echo "=== nm new symbols (unstripped) ==="
for N in /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.noctf /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped; do
  if [ -f "$N" ]; then
    echo "-- $N --"
    "$NM" "$N" 2>/dev/null | grep -E "_star_gpu_speed_tick|_annibale_gpu_speed$|_annibale_gpu_temperature$" | head
  fi
done
echo "=== strings fallback (log messages) ==="
strings -n 8 "$K" | grep -E "GPU.s speed is now|speed changes since it started|no temperature reading|speed vote for" | head
