#!/bin/bash
# s92: full symbol dump attempt on s91 kernel (likely Mach-O arm64e)
K=/root/star26/s91/parts/kernel
file "$K"
echo "===TOOLCHAIN==="
ls /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/ | grep minimac
echo "===OBJ-NM==="
nm /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_minimac.o 2>/dev/null | head -20
echo "===LINKED-KERNEL-VIA-KBUILD==="
find /root/star26/star-native/BUILD -maxdepth 1 -type f | head -10
ls -la /root/star26/star-native/BUILD/ 2>/dev/null | head -10
