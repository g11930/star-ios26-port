#!/bin/bash
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
N=/root/star-build/xnu-deps/host/bin/nm
ls -la --time-style=+%m-%d_%H:%M:%S "$K"
echo "--- symbols"
"$N" "$K" 2>/dev/null | grep -E ' star_gate$| _loader_checkpoint$| _star_trace' | head
echo "--- objects"
find /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837 -name 'loader_return.o' -o -name 'kern_exec.o' | while read f; do
  ls -la --time-style=+%H:%M:%S "$f"
  "$N" "$f" 2>/dev/null | grep -E 'star_gate' | head -3
done
echo "--- strings"
strings -a "$K" | grep -c STARX
