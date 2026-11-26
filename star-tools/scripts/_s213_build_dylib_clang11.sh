#!/bin/bash
# s213: rebuild sb26 dylib with theos clang-11 (ptrauth_calls=1) — the SAME compiler
# that produced the historical 0x80000002 arm64e dylibs.
set -e
U=/root/star26/hackios-xnu-userland/userland
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"
cd "$U"

echo "=== compiler ==="
$TC/clang --version | head -1
echo "=== compile sb26 dylib (theos clang-11, arm64e, ptrauth) ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" \
  -miphoneos-version-min=26.0 -include api_avail_noop.h -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 -Wall -Wextra $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$SDK/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o obj/libannibale-sb26.dylib 2>&1 | tail -25
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
[ "$rc" = 0 ] || exit $rc
echo "=== sign ==="
$TC/ldid -S obj/libannibale-sb26.dylib && echo SIGNED
echo "=== verify ==="
python3 - obj/libannibale-sb26.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('size=%d cputype=%#x cpusubtype=%#x arm64e-PAUTH=%s' % (
    len(d),cpu&0xffffffff,sub&0xffffffff,(sub&0xffffffff)==0x80000002))
PY
md5sum obj/libannibale-sb26.dylib
echo "=== new unlock strings ==="
for s in "waiting for CoverSheet" "layout element" "occlusion reasons" "boot unlock done"; do
  echo "  [$(strings obj/libannibale-sb26.dylib | grep -Fc "$s")] $s"
done
