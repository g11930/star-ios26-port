#!/bin/bash
export PATH=/root/star-build/xnu-deps/host/bin:$PATH
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
echo "=== which nm / llvm-nm ==="
which nm 2>/dev/null
which llvm-nm 2>/dev/null
echo "=== file type ==="
file "$K"
echo "=== nm new symbols ==="
nm "$K" 2>/dev/null | grep -iE "star_gpu_speed_tick|annibale_gpu_speed|annibale_gpu_temperature" | head
echo "=== nm total ==="
nm "$K" 2>/dev/null | wc -l
