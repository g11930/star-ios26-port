#!/usr/bin/env python3
import os, glob
base = "/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib"
keys = [b"shouldForceBitmapImages", b"software_icons_installed", b"hasGlass",
        b"Calendar", b"MTLCreateSystemDefaultDevice", b"icon rendering"]
for p in sorted(glob.glob(base + "/*.dylib")):
    d = open(p, "rb").read()
    hits = {k.decode(): d.count(k) for k in keys if d.count(k)}
    print("%-45s %s" % (os.path.basename(p), hits if hits else "-"))
