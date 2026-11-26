#!/bin/bash
# Rebuild libannibalemetal.dylib for arm64e.
#
# P22 built it arm64 and the device refused it: SpringBoard and backboardd are arm64e processes, and
# dlopen said so -- "have 'arm64', need 'arm64e'". The shipped library was arm64e (359,808 B,
# caps PAC00). This target is therefore arm64e; the kernel's PAC emulation is what lets arm64e run on
# star's ARMv8.2 cores, and the ptrauth.h shim's identity strip stays correct under it.
set -e

U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
OUT=/root/star26/p23
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk

mkdir -p "$OUT" "$U/obj"
cd "$U"

/usr/bin/clang -target arm64e-apple-ios16.5 --ld-path="$LD64" -isysroot "$SDK" \
	-O1 -arch arm64e \
	-include /mnt/d/桌面/star26-deps/shim/star26-userland-shim.h \
	-I/mnt/d/桌面/star26-deps/shim \
	-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I"$DRV" \
	-fno-objc-arc -dynamiclib -install_name /annibale/lib/libannibalemetal.dylib \
	-framework Foundation -framework IOKit -framework Metal -lobjc \
	-o "$OUT/libannibalemetal.dylib" "$DRV/annibalemetal.m" "$DRV/annibaledrawable.m"

ls -la "$OUT/libannibalemetal.dylib"
echo "=== arch ==="
file "$OUT/libannibalemetal.dylib"
echo "=== client-memory path present? ==="
strings "$OUT/libannibalemetal.dylib" | grep -c 'client-memory copy allocation failed'
echo "=== load commands ==="
/root/theos/toolchain/linux/iphone/bin/otool -L "$OUT/libannibalemetal.dylib" 2>&1 | head -12
