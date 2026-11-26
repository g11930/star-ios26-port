#!/bin/bash
KB=/root/star26/kbuild/xnu-12377.121.6
echo "=== how adreno8 gets built ==="
grep -rn 'adreno8' $KB/bsd/dev/Makefile $KB/Makefile $KB/config/* 2>/dev/null | head -20
echo
echo "=== was it ever compiled? ==="
ls -la $KB/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/ 2>/dev/null | grep -i adreno8 | head -8
echo
echo "=== kbuild kernel binary? ==="
ls -la $KB/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 2>/dev/null
echo
echo "=== does it contain adreno strings? ==="
strings -n 6 $KB/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 2>/dev/null | grep -ci 'adreno8\|RBBM'
