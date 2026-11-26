#!/bin/bash
# Build sb26 dylib with theos clang 11 (native arm64e + Apple availability support).
set -e
cd /root/star26/hackios-xnu-userland/userland
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
CLANG=$TC/clang
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/root/star26/star-native/EXTERNAL_HEADERS"

echo "=== clang ==="; $CLANG --version | head -1
echo "=== compile ==="
$CLANG -arch arm64e -isysroot "$SDK" -miphoneos-version-min=16.0 \
  -fobjc-arc -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 -Wall -Wextra $SRC_INC \
  -F"$SDK/System/Library/Frameworks" \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -L"$TC" -fuse-ld="$TC/ld" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -35
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" != "0" ]; then exit $rc; fi
echo "=== sign ==="
$TC/ldid -S obj/libannibale-sb26.dylib && echo SIGNED
echo "=== md5 + strings ==="
md5sum obj/libannibale-sb26.dylib
strings obj/libannibale-sb26.dylib | grep -c "sb26: iconfill" || true
