#!/usr/bin/env python3
"""Check which of the K90 xnu26 patches are already reflected in our tree.

For each patch file (name encodes the target path with % separators), take
up to 6 distinctive '+' lines (len >= 24, not +++/comment-only/#include),
and count how many appear in our tree's corresponding file.  Verdict:
  ABSORBED   at least half of the sampled lines found
  PARTIAL    some found
  MISSING    none found
  NO-FILE    our tree lacks the target file
"""
import glob
import os
import re
import sys

PDIR = "/root/ref2/annibale-kernel/xnu26/patches"
OURS = "/root/star26/star-native"

rows = []
for pf in sorted(glob.glob(PDIR + "/*.patch")):
    base = os.path.basename(pf)
    target = base[len(base.split("-", 1)[0]) + 1:-6].replace("%", "/")
    ours_path = os.path.join(OURS, target)
    try:
        with open(pf, "r", encoding="utf-8", errors="replace") as f:
            ptext = f.read()
    except OSError:
        continue
    added = []
    for line in ptext.splitlines():
        if line.startswith("+") and not line.startswith("+++"):
            s = line[1:].strip()
            if len(s) >= 24 and not s.startswith(("*", "/*", "//")) \
                    and not s.startswith("#include") \
                    and not s.startswith("#define"):
                added.append(s)
        if len(added) >= 6:
            break
    if not os.path.exists(ours_path):
        rows.append((target, base, "NO-FILE", 0, len(added)))
        continue
    with open(ours_path, "r", encoding="utf-8", errors="replace") as f:
        ours_text = f.read()
    found = sum(1 for s in added if s in ours_text)
    if not added:
        rows.append((target, base, "no-sample", 0, 0))
    elif found * 2 >= len(added):
        rows.append((target, base, "ABSORBED", found, len(added)))
    elif found:
        rows.append((target, base, "PARTIAL", found, len(added)))
    else:
        rows.append((target, base, "MISSING", 0, len(added)))

order = {"MISSING": 0, "PARTIAL": 1, "NO-FILE": 2, "ABSORBED": 3, "no-sample": 4}
for target, base, verdict, found, total in sorted(rows, key=lambda r: order[r[2]]):
    print(f"{verdict:9s} {found}/{total}  {base}")

counts = {}
for _, _, v, _, _ in rows:
    counts[v] = counts.get(v, 0) + 1
print("\nsummary:", counts)
