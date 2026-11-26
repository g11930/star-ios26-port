#!/usr/bin/env python3
import os

NEEDLE = b"softpipe half lowering does not support instruction type"
ROOTS = [
    "/root/star26/s42/work/root",
]
hits = []
for root in ROOTS:
    for dirpath, dirnames, filenames in os.walk(root):
        for fn in filenames:
            p = os.path.join(dirpath, fn)
            try:
                if os.path.getsize(p) > 200*1024*1024:
                    continue
                with open(p, "rb") as f:
                    d = f.read()
            except Exception:
                continue
            if NEEDLE in d:
                hits.append((p, len(d)))
print("files containing the string: %d" % len(hits))
for p, sz in hits:
    print("  %10d  %s" % (sz, p))
