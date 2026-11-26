#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

print("mappings covering 0x232fa1ccc:")
for addr, size, foff, p in mappings:
    if addr <= 0x232FA1CCC < addr + size:
        print(f"  addr=0x{addr:x} size=0x{size:x} foff=0x{foff:x} "
            f"{p.split('/')[-1]}")

d = R.read(0x232FA1CCC, 8)
print("stub bytes:", d.hex() if d else None)

# count magics in [vm-4MB, vm]
cnt = 0
first = []
vm = 0x232FA1CD4
lo = vm - 0x400000
blk = 0x100000
end = vm
start = (lo // blk) * blk
while start < end:
    blob = R.read(start, min(blk, end - start))
    if blob:
        i = 0
        while True:
            i = blob.find(b"\xcf\xfa\xed\xfe", i)
            if i < 0:
                break
            cnt += 1
            if len(first) < 5:
                first.append(start + i)
            i += 1
    start += blk
print(f"magics within 4MB below pc: {cnt}")
for v in first:
    print(f"  first hits at vm 0x{v:x}")
