#!/usr/bin/env python3
"""Per-subcache VM mapping: header@0xe0 = VM start; tail metadata (@0x28/0x30)
is not VM content.  Validate against the stub-pattern hits and the
thread_dump printed offsets."""
import glob
import os
import struct

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(glob.glob(D + "/dyld_shared_cache_arm64e") +
    [p for p in glob.glob(D + "/dyld_shared_cache_arm64e.[0-9][0-9]")
        if not p.endswith((".symbols", ".atlas"))],
    key=lambda p: (len(p), p))


def u64(f, o):
    f.seek(o)
    return struct.unpack("<Q", f.read(8))[0]


segs = []
acc = 0
for p in files:
    sz = os.path.getsize(p)
    with open(p, "rb") as f:
        magic = f.read(16)
        vm_start = u64(f, 0xE0)
        map_off = u64(f, 0x28)
        map_sz = u64(f, 0x30)
    tail = map_sz if map_off + map_sz == sz else 0
    vm_span = sz - tail
    segs.append((acc, acc + sz, p, vm_start, vm_span, tail))
    acc += sz

# coverage check: VM ranges (main uses its header's own mapping from 0xe0;
# for main, vm_start@0xe0 was 0x180000000)
prev_end = None
ok = True
for a, b, p, vms, span, tail in segs:
    if prev_end is not None and vms != prev_end:
        print(f"GAP/OVERLAP at {os.path.basename(p)}: "
            f"prev_end 0x{prev_end:x} vs vm_start 0x{vms:x}")
        ok = False
    prev_end = vms + span
print("coverage contiguous:", ok)
print(f"last vm end: 0x{prev_end:x}  (expect ~0x2C2CF8000)")


def vm_to_global(vm):
    for a, b, p, vms, span, tail in segs:
        if vms <= vm < vms + span:
            return a + (vm - vms), p
    return None, None


# the two stub hits (global offsets from probe13)
for g in (0x128cbc, 0x8e625ccc):
    vmv, p = vm_to_global(g)
    print(f"hit global 0x{g:x} ({os.path.basename(p)}) -> vm 0x{vmv:x}")

# thread_dump printed offset -> expected stub vm
print(f"bbd T#0 pc-8 expected vm: 0x{0x180000000 + 0x3d7b1ccc:x}")
