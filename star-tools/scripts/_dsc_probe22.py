#!/usr/bin/env python3
"""Locate image headers by install-name string occurrences, validating that
the string IS that header's LC_ID_DYLIB name; then exercise the export trie.
"""
import glob
import os
import re
import struct
import sys

sys.path.insert(0, "/mnt/d/桌面/star26-deps/scripts")
from dscsym2 import R, mappings

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
files = sorted(p for p in glob.glob(D + "/dyld_shared_cache_arm64e.*")
    if re.search(r"dyld_shared_cache_arm64e\.\d+$", p))


def file_to_vm(p, off):
    for addr, size, foff, pf in mappings:
        if pf == p and foff <= off < foff + size:
            return addr + (off - foff)
    return None


def parse_header(hvm):
    m = R.read(hvm, 0x1000)
    if not m or m[:4] != b"\xcf\xfa\xed\xfe":
        return None
    ncmds = struct.unpack_from("<I", m, 16)[0]
    o = 32
    tva = tsz = None
    idname = None
    trie = None
    for _ in range(ncmds):
        if o + 8 > len(m):
            return None
        cmd, size = struct.unpack_from("<II", m, o)
        if size < 8 or o + size > len(m):
            return None
        if cmd == 0x19:
            seg = m[o + 8:o + 24].split(b"\0")[0].decode("utf-8", "replace")
            if seg == "__TEXT":
                tva = struct.unpack_from("<Q", m, o + 24)[0]
                tsz = struct.unpack_from("<Q", m, o + 32)[0]
        elif cmd == 0xD:
            noff = struct.unpack_from("<I", m, o + 8)[0]
            e = m.find(b"\0", o + noff, min(o + size, len(m)))
            idname = m[o + noff:e].decode("utf-8", "replace")
        elif cmd == 0x80000034:
            trie = (struct.unpack_from("<I", m, o + 8)[0],
                struct.unpack_from("<I", m, o + 12)[0])
        o += size
    if tva is None or idname is None:
        return None
    return (tva, tsz, idname, trie)


TARGETS = [b"/usr/lib/system/libdispatch.dylib",
           b"/usr/lib/system/libxpc.dylib",
           b"/System/Library/Frameworks/CoreFoundation.framework/"
           b"CoreFoundation"]

found = {}
for p in files:
    data = open(p, "rb").read()
    for t in TARGETS:
        i = 0
        while True:
            i = data.find(t, i)
            if i < 0:
                break
            # scan back BYTE-WISE for the referencing header (the string's
            # offset inside the header is arbitrary)
            j = i - 8
            while j >= 0 and i - j < 0x2000:
                if data[j:j + 4] == b"\xcf\xfa\xed\xfe":
                    vm_h = file_to_vm(p, j)
                    h = parse_header(vm_h) if vm_h else None
                    if h and h[2].encode() == t:
                        key = t.decode()
                        found.setdefault(key, (h[0], h[1], vm_h, p))
                        break
                j -= 1
        i += len(t)

for k, (tva, tsz, vm_h, p) in found.items():
    print(f"{k}: __TEXT=0x{tva:x} size=0x{tsz:x} (header vm 0x{vm_h:x}, "
        f"{p.split('/')[-1]})")

# trie validation on libsystem_kernel: the pid_for_task stub at 0x232F09CCC
print()
hdr_kernel = found.get("/usr/lib/system/libdispatch.dylib")
# find libsystem_kernel header via the same method
for p in files:
    data = open(p, "rb").read()
    t = b"/usr/lib/system/libsystem_kernel.dylib"
    i = data.find(t)
    if i < 0:
        continue
    for back in range(0x40, 0x2000, 0x100):
        hoff = i - back
        if hoff < 0:
            break
        if data[hoff:hoff + 4] != b"\xcf\xfa\xed\xfe":
            continue
        vm_h = file_to_vm(p, hoff)
        h = parse_header(vm_h) if vm_h else None
        if h and h[2].encode() == t:
            tva, tsz, _, trie = h
            print(f"libsystem_kernel: __TEXT=0x{tva:x} size=0x{tsz:x}")
            if trie:
                doff, dsize = trie
                tb = R.read(tva + doff, min(dsize, 1 << 22)) or b""
                print(f"trie at image+0x{doff:x} len 0x{dsize:x}: "
                    f"first bytes {tb[:8].hex() if tb else None}")
                # walk for pid_for_task (stub at 0x232F09CCC)
                best = None
                stack = [(0, b"")]

                def leb(p2):
                    r = 0
                    sh = 0
                    while p2 < len(tb):
                        b = tb[p2]
                        p2 += 1
                        r |= (b & 0x7F) << sh
                        if not b & 0x80:
                            return r, p2
                        sh += 7
                    return 0, p2

                while stack:
                    oo, pref = stack.pop()
                    if oo >= len(tb):
                        continue
                    term = tb[oo]
                    p2 = oo + 1
                    svm = None
                    if term:
                        _f, p3 = leb(p2)
                        v, p4 = leb(p3)
                        svm = tva + v
                        if svm <= 0x232F09CD4 and (best is None or
                                svm >= best[0]):
                            best = (svm, pref)
                    ne, p5 = leb(p4 if term else p2)
                    for _ in range(ne):
                        if p5 >= len(tb):
                            break
                        ln = tb[p5]
                        nm = tb[p5 + 1:p5 + 1 + ln]
                        p5 += 1 + ln
                        ch, p5 = leb(p5)
                        stack.append((ch, pref + nm))
                if best:
                    print(f"trie: 0x232f09cd4 -> {best[1].decode()} "
                        f"+0x{0x232F09CD4 - best[0]:x}  ***VALIDATED***"
                        if best[1].decode().endswith("pid_for_task")
                        else f"trie: 0x232f09cd4 -> {best[1].decode()} "
                            f"+0x{0x232F09CD4 - best[0]:x}")
            break
