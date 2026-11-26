#!/bin/bash
cd /tmp || exit 1
printf 'int f(int a){return a+1;}\n' > t.c
CC=/root/xnu26-test/bin/xnu26-clang
echo "=== A: triple arm64e only ==="
XNU_TARGET_TRIPLE=arm64e-apple-ios16.5 "$CC" -O2 -c t.c -o tA.o 2>&1 | head -3
llvm-objdump -d tA.o 2>&1 | sed -n '4,12p'
echo "=== B: triple arm64e + -mkernel ==="
XNU_TARGET_TRIPLE=arm64e-apple-ios16.5 "$CC" -O2 -mkernel -c t.c -o tB.o 2>&1 | head -3
llvm-objdump -d tB.o 2>&1 | sed -n '4,12p'
echo "=== C: plain arm64 (default) ==="
"$CC" -O2 -c t.c -o tC.o 2>&1 | head -3
llvm-objdump -d tC.o 2>&1 | sed -n '4,12p'
echo "=== object cpusubtypes ==="
for f in tA tB tC; do
  printf '%-4s ' "$f"
  python3 -c "
import struct,sys
d=open('/tmp/$f.o','rb').read()
m,ct,cs,ft,nc,sc,fl,r=struct.unpack_from('<IiiIIIII',d,0)
print('cputype 0x%x cpusubtype 0x%x' % (ct&0xffffffff, cs&0xffffffff))
"
done
