#!/usr/bin/env python3
import re, sys, os

files = [
    ("s217(基线,纯模拟)", "D:/ios26/s216-late-*.bin"),
    ("s220(页改写)", "D:/ios26/now-090*.bin"),
]
import glob
paths = []
for label, pat in files:
    for p in sorted(glob.glob(pat)):
        paths.append((label, p))
# also grab any s217 late
for p in sorted(glob.glob("D:/ios26/s217-*.bin")):
    paths.append(("s217(基线)", p))

for label, p in paths:
    print("="*70)
    print(label, os.path.basename(p), os.path.getsize(p))
    try:
        data = open(p, "rb").read().decode("utf-8", "replace")
    except Exception as e:
        print("ERR", e); continue
    lines = data.splitlines()
    print("lines", len(lines))
    # trap/page stat lines
    stats = [l for l in lines if ("pac: traps" in l or "pac_emu_hits" in l or "pac: page" in l) ][:]
    print("pac lines", len(stats))
    for l in stats[:6]: print("  FIRST", l[:160])
    for l in stats[-6:]: print("  LAST ", l[:160])
    # marker timeline
    marks = ["fDeviceFirstUnlocked", "unlockedEnvironmentMode", "SpringBoard[33",
             "unlockUIFromSource", "render pipelines", "FIPSPOST all tests"]
    for m in marks:
        idxs = [i for i,l in enumerate(lines) if m in l]
        print("  MARK", m, "count", len(idxs), "first", idxs[0] if idxs else "-")
