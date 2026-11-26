#!/usr/bin/env python3
import re, os, sys

pat = re.compile(rb"annibale: |COREANIMATION|softpipe|StartWindowServer|metallib|caenv|gl=0|camtl")
for p in ["/mnt/c/ios26/s40-log.bin", "/mnt/c/ios26/s41-staged.bin"]:
    if not os.path.exists(p):
        print("missing", p); continue
    data = open(p, "rb").read()
    print("==== %s (%d B)" % (p, len(data)))
    seen = {}
    for l in data.split(b"\n"):
        if not pat.search(l):
            continue
        s = l.decode("ascii", "replace").strip()
        if s.startswith(("drwxr", "-rwxr", "-rw-r")):
            continue
        seen[s] = seen.get(s, 0) + 1
    print("  distinct: %d" % len(seen))
    for s, n in list(seen.items())[:70]:
        print("   x%-3d %s" % (n, s[:185]))
