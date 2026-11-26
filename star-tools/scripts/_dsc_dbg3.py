#!/usr/bin/env python3
import sys
sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, resolve, image_at

for vm, label in ((0x1800EA000, "libobjc header"),
                  (0x1BE054000, "libdispatch header"),
                  (0x1BE0BA010, "libdispatch+0x66010 (launchd tid214 fr1)"),
                  (0x232F09CD4, "bbd fr0 pc (stub+8)")):
    img = image_at(vm)
    if img:
        tva, tsz, name, trie, _ = img
        print(f"{label}: FOUND name={name!r} __TEXT=0x{tva:x} size=0x{tsz:x}")
    else:
        # count magics within 8MB below
        cnt = 0
        first = []
        start = (vm - 0x800000) // 0x40000 * 0x40000
        end = vm
        while start < end:
            blob = R.read(start, min(0x40000, end - start)) or b""
            i = 0
            while True:
                i = blob.find(b"\xcf\xfa\xed\xfe", i)
                if i < 0:
                    break
                cnt += 1
                if len(first) < 3:
                    first.append(start + i)
                i += 1
            start += 0x40000
        print(f"{label}: NOT FOUND; magics within 8MB below: {cnt}, "
            f"first: {[hex(x) for x in first]}")
