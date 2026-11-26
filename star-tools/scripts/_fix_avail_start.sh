#!/bin/bash
# Fix the buggy early __OSX_AVAILABLE_STARTING definition in theos 16.5 SDK.
T=/root/theos/sdks/iPhoneOS16.5.sdk
AV="$T/usr/include/Availability.h"
cp -a "$AV" "$AV.fixbak213"
restore(){ cp -f "$AV.fixbak213" "$AV"; }
trap restore EXIT
echo "=== context 160-175 before ==="
sed -n '160,175p' "$AV"
python3 - "$AV" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
# The buggy early definition expands to __AVAILABILITY_INTERNAL##_ios which breaks
# clang-11's parsing of sys/time.h. Replace ALL non-noop definitions with empty.
lines=s.splitlines(keepends=True); out=[]; ch=0
for ln in lines:
    st=ln.strip()
    if st.startswith('#define __OSX_AVAILABLE_STARTING') and 'AVAILABILITY_INTERNAL' in st:
        indent=ln[:len(ln)-len(ln.lstrip())]
        out.append(indent+'#define __OSX_AVAILABLE_STARTING(_osx, _ios)\n')
        ch+=1
    else:
        out.append(ln)
open(p,'w').write(''.join(out))
print('fixed',ch,'bad defs')
PY
echo "=== after ==="
grep -n 'define __OSX_AVAILABLE_STARTING' "$AV" | head
echo "=== now compile full dylib (clang-11, API_AVAILABLE noop via -include) ==="
TC=/root/theos/toolchain/linux/iphone/bin
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"
cd "$U"
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$T" \
  -include api_avail_noop.h -dynamiclib -install_name /annibale/lib/libannibale-sb26.dylib -O1 $SRC_INC \
  -framework CoreFoundation -framework Metal -lobjc -lMobileGestalt \
  -fuse-ld="$TC/ld" -L"$T/usr/lib" \
  src/inject/inject_sb26.c src/inject/inject_sb26_layers.c src/inject/inject_sb26_rate.c src/inject/inject_posterboard.c \
  -o /tmp/sb26-fixed-test.dylib 2>&1 | tail -20
rc=${PIPESTATUS[0]}
echo "COMPILE_RC=$rc"
if [ "$rc" = 0 ]; then
  python3 - /tmp/sb26-fixed-test.dylib <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('LINKED cpusubtype=%#x size=%d' % (sub&0xffffffff,len(d)))
PY
fi
