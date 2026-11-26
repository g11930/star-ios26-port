#!/bin/bash
# Rebuild libannibale-sb26.dylib using the theos iPhoneOS16.5 SDK (26 SDK absent in this snapshot).
set -e
cd /root/star26/hackios-xnu-userland/userland
for _d in "$PWD/../../hackios-xnu-kernel/xnu-deps/host/bin" "$PWD/../xnu-deps/host/bin"; do
  [ -d "$_d" ] && export PATH="$_d:$PATH"
done
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/root/star26/star-native/EXTERNAL_HEADERS"
SDK=${HOME}/theos/sdks/iPhoneOS16.5.sdk
LDID_BIN=${LDID:-$HOME/theos/toolchain/linux/iphone/bin/ldid}
[ -x "$LDID_BIN" ] || LDID_BIN=$(command -v ldid)

echo "=== SDK: $SDK ==="
ls "$SDK/usr/lib/libobjc.tbd" >/dev/null 2>&1 && echo "libobjc.tbd present"

echo "=== compile sb26 dylib (arm64e, 16.5 SDK) ==="
xnu-clang -arch arm64e -isysroot "$SDK" -miphoneos-version-min=16.0 \
  -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 -Wall -Wextra $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -30
echo "=== result ==="
ls -la obj/libannibale-sb26.dylib 2>/dev/null && md5sum obj/libannibale-sb26.dylib
