#!/bin/bash
# Rebuild ONLY libannibale-sb26.dylib with the icon-fill patch, replace in the staged root.
set -e
cd /root/star26/hackios-xnu-userland/userland
for _d in "$PWD/../../hackios-xnu-kernel/xnu-deps/host/bin" "$PWD/../xnu-deps/host/bin"; do
  [ -d "$_d" ] && export PATH="$_d:$PATH"
done
DRV=../../hackios-xnu-kernel/tools/userland-driver
[ -d "$DRV" ] || DRV=../tools/userland-driver
THEOS=${THEOS:-$HOME/theos}
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV"
DYN="xnu-clang -arch arm64e -isysroot ../xnu-deps/26/sdk/iPhoneOS.sdk -miphoneos-version-min=26.0 -O1 $SRC_INC"
LDID_BIN=${LDID:-$THEOS/toolchain/linux/iphone/bin/ldid}
[ -x "$LDID_BIN" ] || LDID_BIN=$(command -v ldid)

echo "=== compiler ==="
xnu-clang --version 2>&1 | head -2 || true
echo "=== build dylib ==="
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot ../xnu-deps/26/sdk/iPhoneOS.sdk \
  -miphoneos-version-min=26.0 -dynamiclib \
  -install_name /annibale/lib/libannibale-sb26.dylib -Os $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -20
echo "BUILD_RC=$?"
echo "=== sign ==="
"$LDID_BIN" -S obj/libannibale-sb26.dylib && echo "signed OK"
echo "=== old vs new md5 ==="
md5sum obj/libannibale-sb26.dylib
ROOT=/root/star26/s111/work/rootbuild/root
md5sum "$ROOT/annibale/lib/libannibale-sb26.dylib" 2>/dev/null || echo "staged copy not found"
