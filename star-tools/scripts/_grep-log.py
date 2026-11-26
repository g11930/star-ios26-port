#!/usr/bin/env python3
import re, sys, os

paths = ["/mnt/c/ios26/s40-log.bin", "/mnt/c/ios26/s41-staged.bin", "/mnt/c/ios26/s40-staged.bin"]
for p in paths:
    if not os.path.exists(p):
        continue
    data = open(p, "rb").read()
    print("==== %s (%d bytes)" % (p, len(data)))
    lines = data.split(b"\n")
    pats = re.compile(rb"annibale|COREANIMATION|softpipe|Metal|metallib|CAWindowServer|renderer|StartWindowServer|half lowering")
    hits = [(i, l) for i, l in enumerate(lines) if pats.search(l)]
    print("  matched lines: %d" % len(hits))
    seen = set()
    for i, l in hits:
        s = l.decode("ascii", "replace").strip()
        if s in seen:
            continue
        seen.add(s)
        print("   %6d| %s" % (i, s[:190]))
        if len(seen) > 60:
            print("   ... truncated")
            break
