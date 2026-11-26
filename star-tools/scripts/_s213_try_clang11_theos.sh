#!/bin/bash
# clang-11 (ptrauth=1) + theos 16.5 SDK + availability noop header.
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"
cd "$U"
echo "=== compile clang-11 + theos16.5 + noop ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" \
  -include api_avail_noop.h -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$SDK/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-clang11-test.dylib 2>&1 | tail -25
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-clang11-test.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cpusubtype=%#x size=%d' % (sub&0xffffffff,len(d)))
PY
  echo "PAC count: $(llvm-objdump -d --macho /tmp/sb26-clang11-test.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
fi
