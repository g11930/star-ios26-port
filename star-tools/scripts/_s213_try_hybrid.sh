#!/bin/bash
# Hybrid SDK: theos 16.5 (complete headers) + reconstructed noop availability headers.
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
RS=/root/star26/hackios-xnu-userland/userland/xnu-deps/26/sdk/iPhoneOS.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"

OSAV="$SDK/usr/include/os/availability.h"
AVAIL="$SDK/usr/include/Availability.h"
# backup originals
[ -f "$OSAV.orig213" ] || cp -a "$OSAV" "$OSAV.orig213"
[ -f "$AVAIL.orig213" ] || cp -a "$AVAIL" "$AVAIL.orig213"
restore() {
  cp -f "$OSAV.orig213" "$OSAV"
  cp -f "$AVAIL.orig213" "$AVAIL"
  echo "SDK headers restored"
}
trap restore EXIT

# swap in noop versions from reconstructed SDK
cp -f "$RS/usr/include/os/availability.h" "$OSAV"
cp -f "$RS/usr/include/Availability.h" "$AVAIL"
echo "=== hybrid headers in place ==="
grep -m1 'CLANG18_NOOP\|#if 0' "$AVAIL"
grep -m1 '#if 0\|define API_AVAILABLE' "$OSAV"

cd "$U"
echo "=== compile clang-11 + hybrid SDK ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" \
  -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$SDK/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-hybrid-test.dylib 2>&1 | tail -25
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-hybrid-test.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cpusubtype=%#x size=%d' % (sub&0xffffffff,len(d)))
PY
  echo "PAC count: $(llvm-objdump -d --macho /tmp/sb26-hybrid-test.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
fi
