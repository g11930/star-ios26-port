#!/bin/bash
# Rebuild libannibalemetal.dylib with clang 18 directly.
#
# xnu-clang here cannot be used for userland: its $HB/ld64 link does not exist in this tree (the
# cctools linker lives in the kernel build's host/bin), and it force-includes the kernel's
# xnu_clang_compat.h, which a dylib must not see. Everything else is build.sh's command verbatim.
set -e

U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
OUT=/root/star26/p22
LD64=/root/theos/toolchain/linux/iphone/bin/ld
SDK=/root/theos/sdks/iPhoneOS16.5.sdk

mkdir -p "$OUT" "$U/obj"
cd "$U"

/usr/bin/clang -target arm64-apple-ios16.5 --ld-path="$LD64" -isysroot "$SDK" \
	-O1 -arch arm64 \
	-include /mnt/d/桌面/star26-deps/shim/star26-userland-shim.h \
	-I/mnt/d/桌面/star26-deps/shim \
	-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I"$DRV" \
	-fno-objc-arc -dynamiclib -install_name /annibale/lib/libannibalemetal.dylib \
	-framework Foundation -framework IOKit -framework Metal -lobjc \
	-o "$OUT/libannibalemetal.dylib" "$DRV/annibalemetal.m" "$DRV/annibaledrawable.m"

ls -la "$OUT/libannibalemetal.dylib"
echo "=== client-memory path present? ==="
strings "$OUT/libannibalemetal.dylib" | grep -c 'client-memory copy allocation failed'
echo "=== load commands ==="
/root/theos/toolchain/linux/iphone/bin/otool -L "$OUT/libannibalemetal.dylib" 2>&1 | head -12
echo "=== signature ==="
/root/theos/toolchain/linux/iphone/bin/ldid -h "$OUT/libannibalemetal.dylib" 2>&1 | head -3 || true
