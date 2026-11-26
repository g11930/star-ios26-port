#!/bin/bash
set -e
cd /tmp
python3 - <<'PY'
import struct
b = open('/mnt/c/ios26/p33-payload.bin','rb').read()
off = 8
while off + 24 <= len(b):
    name = b[off:off+16].split(b'\0',1)[0].decode()
    size, _ = struct.unpack_from('<II', b, off+16)
    if name == 'kernel':
        open('/tmp/k33.bin','wb').write(b[off+24:off+24+size])
        print('k33', size)
        break
    off += 24 + ((size+15)//16)*16
PY
K34=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
for f in /tmp/k33.bin "$K34"; do
	echo "=== $f ==="
	llvm-otool-18 -l "$f" | awk '/segname/ {seg=$2} /sectname/ {sect=$2} /addr 0x/ {addr=$2} /^\s+size / {sz=$2} /offset / {if (sect!="") printf "%-22s %-22s addr %s size %s off %s\n", seg, sect, addr, sz, $2; sect=""}' | grep -E 'kalloc|KLD|kmod|constructor|__TEXT_EXEC' | head -20
done
echo "=== 差异：__kalloc_type 段 ==="
for f in /tmp/k33.bin "$K34"; do
	echo "--- $f"
	llvm-otool-18 -l "$f" | grep -A6 'sectname __kalloc_type' | head -12
done
