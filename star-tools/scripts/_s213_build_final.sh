#!/bin/bash
# FINAL s213 dylib build: clang-11 (PAC) + theos 16.5 SDK with two minimal header fixes.
TC=/root/theos/toolchain/linux/iphone/bin
T=/root/theos/sdks/iPhoneOS16.5.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"
OSAV="$T/usr/include/os/availability.h"
AVAIL="$T/usr/include/Availability.h"
cp -a "$OSAV" "$OSAV.finalbak213"
cp -a "$AVAIL" "$AVAIL.finalbak213"
restore(){ cp -f "$OSAV.finalbak213" "$OSAV"; cp -f "$AVAIL.finalbak213" "$AVAIL"; echo "SDK restored"; }
trap restore EXIT

python3 - "$OSAV" "$AVAIL" <<'PY'
import sys,re
# 1) os/availability.h: neutralize new-style API_AVAILABLE/DEPRECATED (GET_MACRO/_Pragma defs)
p=sys.argv[1]; s=open(p).read(); out=[]; c1=0
for ln in s.splitlines(keepends=True):
    m=re.match(r'^(\s*#\s*define\s+)(API_[A-Z_]+)(\([^)]*\))?(.*)$', ln.rstrip('\n'))
    if m and ('GET_MACRO' in m.group(4) or '_Pragma' in m.group(4)):
        out.append(m.group(1)+m.group(2)+'(...)\n'); c1+=1
    else: out.append(ln)
open(p,'w').write(''.join(out))
# 2) Availability.h: neutralize buggy early __OSX_AVAILABLE_STARTING (AVAILABILITY_INTERNAL##)
p=sys.argv[2]; s=open(p).read(); out=[]; c2=0
for ln in s.splitlines(keepends=True):
    st=ln.strip()
    if st.startswith('#define __OSX_AVAILABLE_STARTING') and 'AVAILABILITY_INTERNAL' in st:
        indent=ln[:len(ln)-len(ln.lstrip())]
        out.append(indent+'#define __OSX_AVAILABLE_STARTING(_osx, _ios)\n'); c2+=1
    else: out.append(ln)
open(p,'w').write(''.join(out))
print('neutralized API_=%d OSX_AVAIL=%d' % (c1,c2))
PY

cd "$U"
echo "=== compile clang-11 + patched theos SDK ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$T" \
  -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$T/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-final-test.dylib 2>&1 | tail -20
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-final-test.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('LINKED cputype=%#x cpusubtype=%#x size=%d' % (cpu&0xffffffff,sub&0xffffffff,len(d)))
PY
  echo "PAC count: $(llvm-objdump -d --macho /tmp/sb26-final-test.dylib 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
  echo "new strings: $(strings /tmp/sb26-final-test.dylib | grep -Fc 'waiting for CoverSheet')"
fi
