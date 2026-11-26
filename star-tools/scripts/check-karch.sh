#!/bin/bash
# What architecture is this kernel actually built for -- arm64 or arm64e?
R=/root/star26/star-native
N=/root/star-build/xnu-deps/host/bin/nm
K=$R/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "=== configs available ==="
ls "$R/osfmk/conf/" 2>/dev/null | head -30
echo "=== BUILD dir ==="
ls -d "$R"/BUILD/obj/* 2>/dev/null
echo "=== kernel header arch ==="
/root/star-build/xnu-deps/host/bin/llvm-objdump --macho --private-headers "$K" 2>/dev/null | grep -A4 "LC_BUILD_VERSION" | head -12
echo "=== ptrauth / pac emu symbols in the kernel ==="
"$N" "$K" 2>/dev/null | grep -i -e sleh -e ptrauth -e pac_emu -e arm64e | head -20
echo "=== ARM64E mentions in conf ==="
grep -rn "ARM64E" "$R"/osfmk/conf/* 2>/dev/null | head -10
echo "=== arm64e in the build's own flags ==="
grep -rn "arm64e\|ARM64E" "$R"/makedefs/*.def 2>/dev/null | head -10
