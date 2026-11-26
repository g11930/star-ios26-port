#!/bin/bash
echo "=== [1] K90 release package top-level ==="
find /d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1 -maxdepth 2 -type f 2>/dev/null | head -40

echo ""
echo "=== [2] K90 userland/build scripts anywhere ==="
find /root/star26/k90ref /root/star26/release /d/桌面/star26-deps/k90-ref -type f \( -name "build.sh" -o -name "*sb26*" -o -name "*ptrauth*" -o -name "*subtype*" -o -name "*binpatch*" \) 2>/dev/null | head -40

echo ""
echo "=== [3] any cpusubtype patch tool ==="
grep -rln -i -E "80000002|cpu.?subtype|PTRAUTH" /root/star26/k90ref /root/star26/hackios-xnu-userland /d/桌面/star26-deps/scripts 2>/dev/null | head -30

echo ""
echo "=== [4] K90 dylib vs ours: load command / header diff ==="
python3 - <<'PY'
import struct
paths={
 "k90-v021":"/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib/libannibale-sb26.dylib",
 "clang18-p0":"/tmp/arm64e-probe2/p0.dylib",
 "star-s208":"/tmp/s208rd/lib/libannibale-sb26.dylib",
}
for n,p in paths.items():
    d=open(p,"rb").read()
    magic=d[:4].hex(); cpu,sub=struct.unpack_from("<II",d,4)
    # header fields
    filetype,ncmds,sizeofcmds,flags=struct.unpack_from("<IIII",d,12)
    print("%-12s magic=%s cpu=%s sub=%s filetype=%d ncmds=%d flags=%s"%(
        n,magic,hex(cpu),hex(sub),filetype,ncmds,hex(flags)))
PY
