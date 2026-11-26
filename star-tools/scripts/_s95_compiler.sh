#!/bin/bash
OUT=/mnt/c/ios26/s95_compiler.out
: > "$OUT"
e(){ echo "$@" >> "$OUT"; }
e "=== clang version / targets ==="
clang --version 2>&1 | head -3 >> "$OUT"
e ""
e "=== can clang emit arm64e? (quick test) ==="
echo 'int foo(void){return 1;}' > /tmp/t.c
clang -arch arm64e -isysroot /root/star-build/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk -dynamiclib /tmp/t.c -o /tmp/t.dylib 2>&1 | head -10 >> "$OUT"
e "result dylib:"; ls -la /tmp/t.dylib 2>&1 >> "$OUT"
if [ -f /tmp/t.dylib ]; then file /tmp/t.dylib 2>&1 >> "$OUT"; fi
e ""
e "=== ptrauth support check (what 11-14 lesson said) ==="
clang -arch arm64e -isysroot /root/star-build/xnu-deps/sdk/iPhoneOS16.5.xnu.sdk -dM -E - < /dev/null 2>/dev/null | grep -i ptrauth | head -3 >> "$OUT"
echo "(done)" >> "$OUT"
e ""
e "=== existing dylib cpusubtype (arm64 vs arm64e) ==="
python3 - <<'PY' >> "$OUT"
import struct
p='/root/star26/p38/work/rootbuild/root/lib/libannibale-sb26.dylib'
d=open(p,'rb').read()
# Mach-O header little-endian: magic cputype cpusubtype
magic,cpu,sub=struct.unpack_from('<III',d,0)
print('magic=%x cputype=%x cpusubtype=%x'%(magic,cpu,sub))
print('CPU_SUBTYPE_ARM64E expected subtype=0x80000002')
PY
e ""
e "=== DONE ==="
echo "OK $(wc -c < "$OUT") bytes"
