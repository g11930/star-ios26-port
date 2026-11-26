#!/bin/bash
TC=/root/theos/toolchain/linux/iphone/bin
SDK=/root/theos/sdks/iPhoneOS16.5.sdk
U=/root/star26/hackios-xnu-userland/userland
DRV=/root/star26/hackios-xnu-kernel/tools/userland-driver
SRC_INC="-Isrc/boot -Isrc/inject -Isrc/gfx -Isrc/services -Isrc/apps -Isrc/tests -I$DRV -I/tmp/iconfill_inc -I/root/star26/star-native/EXTERNAL_HEADERS"
OSAV="$SDK/usr/include/os/availability.h"
cp -a "$OSAV" "$OSAV.minbak2"
restore(){ cp -f "$OSAV.minbak2" "$OSAV"; }
trap restore EXIT
# neutralize new-style API_AVAILABLE only
python3 - "$OSAV" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read(); out=[]; ch=0
for ln in s.splitlines(keepends=True):
    m=re.match(r'^(\s*#\s*define\s+)(API_[A-Z_]+)(\([^)]*\))?(.*)$', ln.rstrip('\n'))
    if m and ('GET_MACRO' in m.group(4) or '_Pragma' in m.group(4)):
        out.append(m.group(1)+m.group(2)+'(...)\n'); ch+=1
    else: out.append(ln)
open(p,'w').write(''.join(out)); print('neutralized',ch)
PY
cd "$U"
echo "=== compile inject_sb26.c ONLY (clang-11, no posterboard) ==="
$TC/clang -target arm64e-apple-ios16.5 -isysroot "$SDK" -O1 $SRC_INC \
  -c src/inject/inject_sb26.c -o /tmp/inject_sb26_only.o 2>&1 | tail -15
rc=${PIPESTATUS[0]}
echo "RC=$rc"
if [ "$rc" = 0 ]; then
python3 - /tmp/inject_sb26_only.o <<'PY'
import struct,sys
d=open(sys.argv[1],'rb').read()
cpu,sub=struct.unpack_from('<ii',d,4)
print('cputype=%#x cpusubtype=%#x' % (cpu&0xffffffff,sub&0xffffffff))
PY
echo "PAC count: $(llvm-objdump -d --macho /tmp/inject_sb26_only.o 2>/dev/null | grep -icE 'pacibsp|paciasp|autibsp|autiasp|blraa|braa|ldraa|xpaci')"
fi
