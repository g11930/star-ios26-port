#!/usr/bin/env python3
import os, re, sys, subprocess

ROOT = "/root/star26/s41/work/root"
if not os.path.isdir(ROOT):
    # fallback: newest p*/work/root
    cands = []
    for d in sorted(os.listdir("/root/star26")):
        p = os.path.join("/root/star26", d, "work", "root")
        if os.path.isdir(p):
            cands.append((os.path.getmtime(p), p))
    cands.sort()
    ROOT = cands[-1][1]
print("ROOT =", ROOT)

def strings(path, minlen=6):
    out = []
    try:
        data = open(path, "rb").read()
    except Exception as e:
        return out
    for m in re.finditer(rb"[\x20-\x7e]{%d,}" % minlen, data):
        out.append(m.group().decode("ascii", "replace"))
    return out

# 1) which binaries mention softpipe / half lowering
print("\n== scan for 'softpipe' / 'half lowering' ==")
hits = {}
for base, dirs, files in os.walk(ROOT):
    for f in files:
        p = os.path.join(base, f)
        try:
            if os.path.getsize(p) > 80 * 1024 * 1024:
                continue
            data = open(p, "rb").read()
        except Exception:
            continue
        if b"half lowering" in data or b"softpipe" in data:
            n1 = data.count(b"half lowering")
            n2 = data.count(b"softpipe")
            hits[os.path.relpath(p, ROOT)] = (n1, n2)
for k, v in sorted(hits.items()):
    print("  %-60s half_lowering=%d softpipe=%d" % (k, v[0], v[1]))
if not hits:
    print("  (none)")
