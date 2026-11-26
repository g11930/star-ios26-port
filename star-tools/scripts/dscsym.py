#!/usr/bin/env python3
"""Symbolize thread_dump frame offsets (23G90 split dyld cache).

Usage: dscsym.py <printed_offset_hex> ...

thread_dump prints pc - region_start; the kernel reports the cache's
mapping granularity, and all our frames sit in the big __TEXT mapping
whose unslid start is 0x1F57F0000 (derived from the pid_for_task stub
pattern hit).  For each offset:
  vm = 0x1F57F0000 + off  ->  image whose range covers vm  ->  export trie
"""
import glob
import os
import re
import struct
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
BASE = 0x1F57F0000  # unslid start of the __TEXT mapping (validated)


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


def fu64(f, o):
    f.seek(o)
    return struct.unpack("<Q", f.read(8))[0]


files = sorted(p for p in glob.glob(D + "/dyld_shared_cache_arm64e.*")
    if re.search(r"dyld_shared_cache_arm64e\.\d+$", p))
mappings = []
for p in files:
    sz = os.path.getsize(p)
    if sz < 0x250:
        continue
    with open(p, "rb") as f:
        moff = fu64(f, 0x10)
        mcnt = fu64(f, 0x14) & 0xFFFFFFFF
        if moff == 0 or mcnt == 0 or mcnt > 16 or moff + mcnt * 24 + 8 > sz:
            moff, mcnt = 0x228, 1
        for i in range(mcnt):
            addr = fu64(f, moff + i * 24)
            size = fu64(f, moff + i * 24 + 8)
            foff = fu64(f, moff + i * 24 + 16)
            if addr and size:
                mappings.append((addr, size, foff, p))


class Reader:
    def __init__(self):
        self.caches = {}
        for addr, size, foff, p in mappings:
            self.caches.setdefault(p, []).append((addr, size, foff))

    def read(self, vm, n):
        for p, ms in self.caches.items():
            for addr, size, foff in ms:
                if addr <= vm < addr + size:
                    with open(p, "rb") as f:
                        f.seek(foff + (vm - addr))
                        return f.read(n)
        return None


def main():
    r = Reader()
    # image table from the main header: stride 32 at 0x2b0, 0x228 entries
    hdr = open(D + "/dyld_shared_cache_arm64e", "rb").read(0x98000)
    images = []
    o = 0x2B0
    for _ in range(0x228):
        po = u32(hdr, o)
        vm = u64(hdr, o + 8)
        if po and vm:
            e = hdr.find(b"\0", po, po + 250)
            path = hdr[po:e].decode("utf-8", "replace")
            images.append((vm, path))
        o += 32
    images.sort()
    print(f"images: {len(images)}", file=sys.stderr)

    def image_for(vm):
        best = None
        for vmaddr, path in images:
            if vmaddr <= vm:
                best = (vmaddr, path)
            else:
                break
        return best

    for arg in sys.argv[1:]:
        off = int(arg, 16)
        vm = BASE + off
        img = image_for(vm)
        if not img:
            print(f"0x{off:x} -> ? (no image)")
            continue
        ivm, path = img
        # read the image's Mach-O header at its vmaddr
        m = r.read(ivm, 0x4000)
        if not m or m[:4] != b"\xcf\xfa\xed\xfe":
            print(f"0x{off:x} -> {os.path.basename(path)}+0x{vm - ivm:x}")
            continue
        ncmds = u32(m, 16)
        o2 = 32
        tvm = None
        tsz = 0
        for _ in range(ncmds):
            cmd, size = u32(m, o2), u32(m, o2 + 4)
            if cmd == 0x19:
                seg = m[o2 + 8:o2 + 24].split(b"\0")[0].decode()
                if seg == "__TEXT":
                    tvm = u64(m, o2 + 16)
                    tsz = u64(m, o2 + 24)
            o2 += size
        # find the symbol in the export trie (LC_DYLD_EXPORTS_TRIE)
        name = None
        symvm = None
        o2 = 32
        for _ in range(ncmds):
            cmd, size = u32(m, o2), u32(m, o2 + 4)
            if cmd == 0x80000034:
                doff = u32(m, o2 + 8)
                dsize = u32(m, o2 + 12)
                # trie bytes live at tvm + doff (offset within the image)
                trie = r.read(ivm + doff, min(dsize, 1 << 22)) or b""
                best = None
                stack = [(0, b"")]
                while stack:
                    oo, pref = stack.pop()
                    if oo >= len(trie):
                        continue
                    term = trie[oo]
                    p2 = oo + 1

                    def leb(p2):
                        r2 = 0
                        sh = 0
                        while True:
                            b = trie[p2]
                            p2 += 1
                            r2 |= (b & 0x7F) << sh
                            if not b & 0x80:
                                return r2, p2
                            sh += 7

                    symvm2 = None
                    if term:
                        _f, p3 = leb(p2)
                        v, p4 = leb(p3)
                        symvm2 = ivm + v
                        if symvm2 <= vm and (best is None or
                                symvm2 >= best[0]):
                            best = (symvm2, pref)
                    ne, p5 = leb(p4 if term else p2)
                    for _ in range(ne):
                        ln = trie[p5]
                        nm = trie[p5 + 1:p5 + 1 + ln]
                        p5 += 1 + ln
                        ch, p5 = leb(p5)
                        stack.append((ch, pref + nm))
                if best:
                    name = best[1].decode("utf-8", "replace")
                    symvm = best[0]
            o2 += size
        rel = vm - ivm
        if name:
            print(f"0x{off:x} -> {os.path.basename(path)}  {name}"
                f"+0x{vm - symvm:x}")
        else:
            print(f"0x{off:x} -> {os.path.basename(path)}+0x{rel:x}")


if __name__ == "__main__":
    main()
