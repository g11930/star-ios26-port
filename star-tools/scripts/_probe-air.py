#!/usr/bin/env python3
import os, re

ROOT = "/root/star26/s41/work/root"

def strings(path, minlen=5):
    data = open(path, "rb").read()
    return [m.group().decode("ascii", "replace")
            for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, data)]

def show(title, path, pats, limit=400):
    print("\n==== %s (%s) ====" % (title, path))
    if not os.path.exists(path):
        print("  MISSING")
        return
    print("  size=%d" % os.path.getsize(path))
    ss = strings(path)
    print("  total strings=%d" % len(ss))
    rx = re.compile("|".join(pats), re.I)
    n = 0
    for s in ss:
        if rx.search(s):
            print("   ", s[:200])
            n += 1
            if n >= limit:
                print("    ...")
                break

show("air", ROOT + "/lib/libannibaleair.dylib",
     [r"softpipe", r"half", r"lower", r"unsupported", r"gallium", r"llvmpipe",
      r"tgsi", r"nir", r"annibale", r"^MTL", r"backend", r"shader"])

show("metal", ROOT + "/lib/libannibalemetal.dylib",
     [r"softpipe", r"half", r"lower", r"gallium", r"llvmpipe", r"tgsi",
      r"annibale", r"^MTL", r"backend", r"env", r"GALLIUM"])

show("annibale-core", ROOT + "/lib/libannibale.dylib",
     [r"caenv", r"ca_vbl", r"ca_", r"metal", r"^annibale:", r"COREANIMATION",
      r"softpipe", r"renderer"])
