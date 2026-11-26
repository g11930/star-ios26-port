#!/bin/bash
# Reproduce build.sh's exact iOS26 dylib compile line (Linux/xnu-clang branch).
set -e
cd /root/star26/hackios-xnu-userland/userland
for _d in "$PWD/../../hackios-xnu-kernel/xnu-deps/host/bin" "$PWD/../xnu-deps/host/bin"; do
  [ -d "$_d" ] && export PATH="$_d:$PATH"
done
THEOS=${THEOS:-$HOME/theos}
export THEOS
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/root/star26/star-native/EXTERNAL_HEADERS"
LDID=${LDID:-$THEOS/toolchain/linux/iphone/bin/ldid}

echo "=== xnu-clang $(command -v xnu-clang) ==="
echo "=== exact build line ==="
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot "$THEOS/sdks/iPhoneOS16.5.sdk" \
  -miphoneos-version-min=26.0 -include api_avail_noop.h \
  -dynamiclib \
  -install_name /annibale/lib/libannibale-sb26.dylib -Os $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -35
echo "RC=${PIPESTATUS[0]}"
ls -la obj/libannibale-sb26.dylib 2>/dev/null && md5sum obj/libannibale-sb26.dylib
