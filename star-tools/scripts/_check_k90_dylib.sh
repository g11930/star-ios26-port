#!/bin/bash
echo "=== K90 userland repo: prebuilt sb26 dylib? ==="
find /root/star26/k90ref -iname 'libannibale-sb26*.dylib' 2>/dev/null | head
echo "=== any prebuilt dylibs in K90 docs/scripts ==="
find /root/star26/k90ref -iname '*.dylib' 2>/dev/null | head -20
echo "=== K90 build docs: how sb26 dylib is built / arch ==="
grep -rn -iE 'arm64e|cpusubtype|ptrauth|0x80000002|sb26.*dylib.*build|clang.*sb26' /root/star26/k90ref/docs/docs 2>/dev/null | head -25
echo "=== star: any 0x2 dylib ever worked? check s40/s111 prebuilt ==="
python3 - <<'PY'
import glob,struct,os
for p in glob.glob('/root/star26/s*/work/root*/lib/libannibale-sb26.dylib')[:10]:
    d=open(p,'rb').read()
    cpu,sub=struct.unpack_from('<ii',d,4)
    print(f"{p}: cpusubtype={sub&0xffffffff:#x} size={len(d)}")
PY
