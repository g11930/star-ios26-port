#!/usr/bin/env python3
import struct, hashlib, os

def sections(path):
    d = open(path, "rb").read()
    magic = struct.unpack("<I", d[:4])[0]
    if magic != 0xfeedfacf:
        return None
    ncmds = struct.unpack("<I", d[16:20])[0]
    p = 32
    out = {}
    segs = {}
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack("<II", d[p:p+8])
        if cmd == 0x19:
            name = d[p+8:p+24].rstrip(b"\x00").decode()
            vmaddr, vmsize, fileoff, filesize = struct.unpack("<QQQQ", d[p+24:p+56])
            segs[name] = (fileoff, filesize)
            nsects = struct.unpack("<I", d[p+64:p+68])[0]
            q = p + 72
            for _ in range(nsects):
                sname = d[q:q+16].rstrip(b"\x00").decode()
                segn  = d[q+16:q+32].rstrip(b"\x00").decode()
                addr, size, offset = struct.unpack("<QQI", d[q+32:q+52])
                out["%s,%s" % (segn, sname)] = (offset, size)
                q += 80
        p += cmdsize
    return d, out, segs

NEW = "/root/star26/s42/work/root/lib/libannibaleair.dylib"
OLD = "/root/star26/s41/work/root/lib/libannibaleair.dylib"

dn, sn, gn = sections(NEW)
do, so, go = sections(OLD)

keys = sorted(set(sn) | set(so))
print("%-30s %12s %12s  %s" % ("section", "new_size", "old_size", "identical"))
for k in keys:
    a = sn.get(k); b = so.get(k)
    if a is None or b is None:
        print("%-30s %12s %12s  %s" % (k, a[1] if a else "-", b[1] if b else "-", "MISSING"))
        continue
    ha = hashlib.sha256(dn[a[0]:a[0]+a[1]]).hexdigest()[:16]
    hb = hashlib.sha256(do[b[0]:b[0]+b[1]]).hexdigest()[:16]
    print("%-30s %12d %12d  %s  %s/%s" % (k, a[1], b[1], "SAME" if ha == hb else "DIFF", ha, hb))

print()
for name in ("__TEXT", "__LINKEDIT", "__DATA"):
    print("%-12s new=%s old=%s" % (name, gn.get(name), go.get(name)))
