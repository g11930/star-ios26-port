#!/bin/bash
# Build sb26 dylib with the reconstructed iOS26 SDK (Availability noop patch applied).
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
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
LDID=${LDID:-$THEOS/toolchain/linux/iphone/bin/ldid}

echo "=== SDK check ==="
test -f "$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" && echo SDK_OK

echo "=== compile ==="
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot "$SDK" \
  -miphoneos-version-min=26.0 -dynamiclib \
  -install_name /annibale/lib/libannibale-sb26.dylib -Os $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c \
  src/inject/inject_posterboard.c -o obj/libannibale-sb26.dylib 2>&1 | tail -35
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" != "0" ]; then exit $rc; fi
echo "=== sign ==="
"$LDID" -S obj/libannibale-sb26.dylib && echo SIGNED
echo "=== md5 + strings check ==="
md5sum obj/libannibale-sb26.dylib
strings obj/libannibale-sb26.dylib | grep -c "sb26: iconfill" || echo "NO iconfill string"
