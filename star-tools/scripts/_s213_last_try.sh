#!/bin/bash
# Last attempt: clang-11 + theos SDK, minimal API_AVAILABLE noop, _POSIX_C_SOURCE to skip bad decls,
# explicit stdatomic include path.
TC=/root/theos/toolchain/linux/iphone/bin
T=/root/theos/sdks/iPhoneOS16.5.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
CLANGINC=/root/theos/toolchain/linux/iphone/lib/clang/11.1.0/include
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS -I$CLANGINC"
OSAV="$T/usr/include/os/availability.h"
cp -a "$OSAV" "$OSAV.lastbak213"
restore(){ cp -f "$OSAV.lastbak213" "$OSAV"; rm -f "$OSAV.lastbak213"; }
trap restore EXIT
python3 - "$OSAV" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read(); out=[]
for ln in s.splitlines(keepends=True):
    m=re.match(r'^(\s*#\s*define\s+)(API_[A-Z_]+)(\([^)]*\))?(.*)$', ln.rstrip('\n'))
    if m and ('GET_MACRO' in m.group(4) or '_Pragma' in m.group(4)):
        out.append(m.group(1)+m.group(2)+'(...)\n')
    else: out.append(ln)
open(p,'w').write(''.join(out))
print('done')
PY
cd "$U"
echo "=== compile ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$T" \
  -D_POSIX_C_SOURCE=200809L -D_DARWIN_C_SOURCE=0 \
  -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$T/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-last.dylib 2>&1 | tail -18
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-last.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('LINKED cpusubtype=%#x size=%d' % (sub&0xffffffff,len(d)))
PY
  echo "PAC count: $(llvm-objdump -d --macho /tmp/sb26-last.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
fi
