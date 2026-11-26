#!/usr/bin/env python3
"""Final frame resolver for the s78 thread_dump output.

Coordinate systems (all validated against the pid_for_task stub bytes
d0058092/011000d4 found in dyld_shared_cache_arm64e.46):
  fr offsets (tl: td N tid T fr i -+OFF)  -> unslid = 0x1F57F0000 + OFF
  raw bt/bt+ pcs (tl: td N tid T bt+ ADDR) -> unslid = ADDR - 0x1C410000
    (the printed task slide 0x1c4a8000 is 0x98000 too large)

Image lookup: backward 4K-page scan for the Mach-O magic, parse
LC_SEGMENT_64 __TEXT containment + LC_ID_DYLIB install name, then
LC_DYLD_EXPORTS_TRIE for the symbol (trie vm = image vmaddr + dataoff,
validated: must resolve pid_for_task for the known stub).
"""
import glob
import os
import re
import struct
import sys

D = "/root/dsc26/System/Library/Caches/com.apple.dyld"
FR_BASE = 0x1F5758000
TRUE_SLIDE = 0x1C4A8000


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
        self.by_file = {}
        for addr, size, foff, p in mappings:
            self.by_file.setdefault(p, []).append((addr, size, foff))

    def read(self, vm, n):
        for p, ms in self.by_file.items():
            for addr, size, foff in ms:
                if addr <= vm < addr + size:
                    with open(p, "rb") as f:
                        f.seek(foff + (vm - addr))
                        return f.read(n)
        return None


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def u64(b, o):
    return struct.unpack_from("<Q", b, o)[0]


R = Reader()
_img_cache = {}


def image_at(vm):
    """backward BLOCK scan for the containing image (headers are NOT page
    aligned in the cache); returns (base_vm, tsz, name, trie, macho)."""
    if vm in _img_cache:
        return _img_cache[vm]
    result = None
    blk = 0x40000                  # 256 KB blocks, scanned downward
    lo = max(0x180000000, vm - 0x2000000)   # ≤32 MB back
    end = (vm | 0x3FFFF) + 1
    start = vm & ~0x3FFFF
    while start >= lo and not result:
        blob = R.read(start, end - start)
        if blob:
            pos = len(blob) - 4
            while pos >= 0:
                pos = blob.rfind(b"\xcf\xfa\xed\xfe", 0, pos + 4)
                if pos < 0:
                    break
                hvm = start + pos
                m = blob[pos:pos + 0x4000]
                if len(m) < 0x4000:
                    extra = R.read(hvm + len(m), 0x4000 - len(m)) or b""
                    m = (m + extra)[:0x4000]
                ncmds = u32(m, 16)
                o = 32
                tva = tsz = None
                name = None
                trie = None
                for _ in range(min(ncmds, 4096)):
                    if o + 8 > len(m):
                        break
                    cmd, size = u32(m, o), u32(m, o + 4)
                    if size < 8 or o + size > len(m):
                        break
                    if cmd == 0x19:  # LC_SEGMENT_64
                        seg = m[o + 8:o + 24].split(b"\0")[0].decode(
                            "utf-8", "replace")
                        if seg == "__TEXT":
                            tva = u64(m, o + 24)   # vmaddr @cmd+24
                            tsz = u64(m, o + 32)   # vmsize @cmd+32
                    elif cmd == 0xD:  # LC_ID_DYLIB
                        noff = u32(m, o + 8)
                        e = m.find(b"\0", o + noff, min(o + size, len(m)))
                        name = m[o + noff:e].decode("utf-8", "replace")
                    elif cmd == 0x80000034:
                        trie = (u32(m, o + 8), u32(m, o + 12))
                    o += size
                    if tva and name and trie:
                        break
                if tva and tva <= vm < tva + tsz:
                    result = (tva, tsz, name or "?", trie, m)
                    break
                pos -= 1
        end = start
        start -= blk
    _img_cache[vm] = result
    return result


def trie_lookup(img, want_vm):
    tva, tsz, name, trie_cmd, m = img
    if not trie_cmd:
        return None
    doff, dsize = trie_cmd
    for base in (tva,):            # trie vm = image vmaddr + dataoff
        trie = R.read(base + doff, min(dsize, 1 << 22))
        if not trie:
            continue
        best = None
        stack = [(0, b"")]

        def leb(p):
            r = 0
            sh = 0
            while p < len(trie):
                b = trie[p]
                p += 1
                r |= (b & 0x7F) << sh
                if not b & 0x80:
                    return r, p
                sh += 7
            return 0, p

        while stack:
            oo, pref = stack.pop()
            if oo >= len(trie):
                continue
            term = trie[oo]
            p2 = oo + 1
            symvm = None
            if term:
                _f, p3 = leb(p2)
                v, p4 = leb(p3)
                symvm = tva + v
                if symvm <= want_vm and (best is None or symvm >= best[0]):
                    best = (symvm, pref)
            ne, p5 = leb(p4 if term else p2)
            for _ in range(ne):
                if p5 >= len(trie):
                    break
                ln = trie[p5]
                nm = trie[p5 + 1:p5 + 1 + ln]
                p5 += 1 + ln
                ch, p5 = leb(p5)
                stack.append((ch, pref + nm))
        return best
    return None


def resolve(vm):
    img = image_at(vm)
    if not img:
        return "?vm 0x%x" % vm
    tva, tsz, name, trie_cmd, _ = img
    base = os.path.basename(name) if name and name != "?" else "?"
    hit = trie_lookup(img, vm)
    if hit:
        return f"{base}\t{hit[1].decode('utf-8', 'replace')}+0x{vm - hit[0]:x}"
    return f"{base}+0x{vm - tva:x}"


if __name__ == "__main__":
    # self-validation: the pid_for_task stub pc must resolve
    v = resolve(0x1F57F0000 + 0x3d7b1cd4)
    print("validate bbd fr0:", v, file=sys.stderr)

    log = open("/mnt/c/ios26/s78-log.bin", "rb").read().replace(
        b"\0", b"").decode("utf-8", "replace")
    # per-thread frames
    cur = None
    stacks = {}
    for m in re.finditer(
            r"tl: td (\d+) tid (\d+) (bt|bt\+|fr) ([^\n]*?)\n", log):
        pid, tid, kind, rest = m.groups()
        key = (int(pid), int(tid))
        stacks.setdefault(key, [])
        if kind == "fr":
            mm = re.match(r"(-)\+([0-9a-f]+)", rest)
            if mm:
                stacks[key].append(
                    (int(mm.group(2), 16) + FR_BASE, "fr"))
        elif kind in ("bt", "bt+"):
            for tok in rest.split():
                if tok.startswith("100") or tok.startswith("0"):
                    continue  # launchd-binary / null frames handled separately
                try:
                    a = int(tok, 16)
                except ValueError:
                    continue
                if a > 0x180000000:
                    stacks[key].append((a - TRUE_SLIDE, "bt"))

    for (pid, tid), frames in sorted(stacks.items()):
        print(f"=== pid {pid} tid {tid} ===")
        for vm, kind in frames:
            print(f"  [{kind}] 0x{vm:x} -> {resolve(vm)}")
