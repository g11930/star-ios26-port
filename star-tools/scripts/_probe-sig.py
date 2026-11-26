#!/usr/bin/env python3
import struct
def loadcmds(p):
    d = open(p, "rb").read()
    magic, ct, cs, ft, ncmds, sz, fl = struct.unpack_from("<IiiIIII", d, 0)
    off = 32
    out = []
    for _ in range(ncmds):
        cmd, csz = struct.unpack_from("<II", d, off)
        out.append((cmd, csz, off))
        off += csz
    return d, out

NEW = "/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/src/gallium/drivers/freedreno/libannibaleair.dylib"
OLD = "/root/star26/s41/work/root/lib/libannibaleair.dylib"
names = {0x1d: "LC_CODE_SIGNATURE", 0x32: "LC_BUILD_VERSION", 0x80000022: "LC_DYLD_INFO_ONLY",
         0x19: "LC_SEGMENT_64", 0xc: "LC_LOAD_DYLIB"}
for p in (NEW, OLD):
    d, cmds = loadcmds(p)
    kinds = {}
    for cmd, csz, off in cmds:
        kinds.setdefault(cmd, 0)
        kinds[cmd] += 1
        if cmd == 0x1d:
            dataoff, datasize = struct.unpack_from("<II", d, off + 8)
            print("%s: LC_CODE_SIGNATURE dataoff=%d size=%d" % (p.split('/')[-2], dataoff, datasize))
    print("  %s -> %s (filesize %d)" % (p.split('/')[-1], {hex(k): v for k, v in sorted(kinds.items())}, len(d)))
