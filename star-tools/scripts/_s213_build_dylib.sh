#!/bin/bash
# s213: rebuild ONLY libannibale-sb26.dylib with new unlock logic.
set -e
U=/root/star26/hackios-xnu-userland/userland
K=/root/star26/hackios-xnu-kernel
HDRS="$K/xnu-deps/host/bin"
DRV="$K/tools/userland-driver"
[ -d "$U/../xnu-deps/host/bin" ] && HDRS="$U/../xnu-deps/host/bin:$HDRS"
export PATH="$HDRS:$PATH"
export XNU_SDK_VERSION=26.0
THEOS=${THEOS:-/root/theos}
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/root/star26/star-native/EXTERNAL_HEADERS"
LDID=$THEOS/toolchain/linux/iphone/bin/ldid
cd "$U"

echo "=== xnu-clang resolve ==="
command -v xnu-clang
echo "=== compile sb26 dylib (arm64e, reconstructed iOS26 SDK with availability=noop patch) ==="
SDK="$U/xnu-deps/26/sdk/iPhoneOS.sdk"
test -f "$SDK/System/Library/Frameworks/CoreFoundation.framework/Headers/CoreFoundation.h" && echo SDK_OK
XNU_SDK_VERSION=26.0 xnu-clang -arch arm64e -isysroot "$SDK" \
    -miphoneos-version-min=26.0 -include api_avail_noop.h -dynamiclib \
    -install_name /annibale/lib/libannibale-sb26.dylib -Os $SRC_INC \
    -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
    src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
    -o obj/libannibale-sb26.dylib

echo "=== ldid sign ==="
"$LDID" -S obj/libannibale-sb26.dylib && echo SIGNED
echo "=== result ==="
md5sum obj/libannibale-sb26.dylib
python3 - obj/libannibale-sb26.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('size=%d cputype=%#x cpusubtype=%#x arm64e=%s' % (
    len(d), cpu&0xffffffff, sub&0xffffffff, (sub&0xffffffff)==0x80000002))
PY
echo "=== new unlock strings present? ==="
strings obj/libannibale-sb26.dylib | grep -E "waiting for CoverSheet|layout element|occlusion reasons|boot unlock done" | head -10
