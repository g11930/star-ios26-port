#!/usr/bin/env python3
import os, re, glob
root = "/root/star26/s42/work/root"
keys = [b"ANNIBALE_SB_METAL", b"ANNIBALE_DUMP_AIR", b"ANNIBALE_DIAG", b"GANGLIUM", b"GALLIUM_DRIVER"]
for p in sorted(glob.glob(root + "/lib/*.dylib")) + sorted(glob.glob(root + "/bin/*")):
    try:
        d = open(p, "rb").read()
    except Exception:
        continue
    hit = [k.decode() for k in keys if k in d]
    if hit:
        print("%-46s %s" % (os.path.basename(p), ",".join(hit)))
