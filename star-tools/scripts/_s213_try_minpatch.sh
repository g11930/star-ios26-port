#!/bin/bash
# Minimal patch: only neutralize NEW-style API_AVAILABLE in theos 16.5 os/availability.h.
# Keep all legacy __OSX_AVAILABLE_STARTING / __API_UNAVAILABLE macros intact (needed by sys/time.h).
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"

OSAV="$SDK/usr/include/os/availability.h"
[ -f "$OSAV.minbak213" ] || cp -a "$OSAV" "$OSAV.minbak213"
restore() { cp -f "$OSAV.minbak213" "$OSAV"; echo "os/availability.h restored"; }
trap restore EXIT

python3 - "$OSAV" <<'PY'
import sys,re
p=sys.argv[1]
s=open(p).read()
out=[]
ch=0
for ln in s.splitlines(keepends=True):
    m=re.match(r'^(\s*#\s*define\s+)(API_[A-Z_]+)(\([^)]*\))?(.*)$', ln.rstrip('\n'))
    if m and ('GET_MACRO' in m.group(4) or '_Pragma' in m.group(4)):
        out.append(m.group(1)+m.group(2)+'(...)\n')
        ch+=1
    else:
        out.append(ln)
open(p,'w').write(''.join(out))
print('neutralized',ch,'API_ macros in os/availability.h')
PY
grep -nE 'define API_AVAILABLE|define API_DEPRECATED' "$OSAV" | head

cd "$U"
echo "=== compile clang-11 + min-patched theos SDK ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" \
  -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$SDK/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-minpatch-test.dylib 2>&1 | tail -20
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-minpatch-test.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cpusubtype=%#x size=%d' % (sub&0xffffffff,len(d)))
PY
  echo "PAC count: $(llvm-objdump -d --macho /tmp/sb26-minpatch-test.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
fi
