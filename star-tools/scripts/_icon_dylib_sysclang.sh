#!/bin/bash
# Build sb26 dylib with SYSTEM clang 18 (native API_AVAILABLE support) + theos SDK + ld64.
set -e
cd /root/star26/hackios-xnu-userland/userland
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
CLANG=/usr/bin/clang
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc"

echo "=== compile (system clang, arm64e) ==="
$CLANG -target arm64e-apple-ios16.5 -isysroot "$SDK" \
  -fobjc-arc -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib \
  -O1 -Wall -Wextra $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$SDK/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -40
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" != "0" ]; then exit $rc; fi
echo "=== sign ==="
$TC/ldid -S obj/libannibale-sb26.dylib && echo SIGNED
echo "=== verify ==="
file obj/libannibale-sb26.dylib 2>/dev/null || true
md5sum obj/libannibale-sb26.dylib
strings obj/libannibale-sb26.dylib | grep -c "sb26: iconfill" || true
