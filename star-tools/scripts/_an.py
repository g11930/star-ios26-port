#!/usr/bin/env python3
"""判读 s41/s42 的 staged 日志：lsprobe 时间线、CA/Metal 决策、stall 头、崩溃报告。"""
import re, sys, os

p = sys.argv[1] if len(sys.argv) > 1 else "/mnt/c/ios26/s41-staged.bin"
data = open(p, "rb").read()
lines = data.decode("ascii", "replace").split("\n")
print("== %s (%d bytes, %d lines)" % (p, len(data), len(lines)))

print("\n---- lsprobe ----")
for l in lines:
    if "lsprobe t=" in l:
        print("  ", l.strip()[:300])

print("\n---- annibale / CA / display ----")
pat = re.compile(r"annibale: |annibalemetal\[|COREANIMATION|softpipe|half lowering|"
                 r"StartWindowServer|iomfb_populate|metallib|CoreAnimation")
seen = {}
for l in lines:
    if not pat.search(l):
        continue
    s = l.strip()
    if s.startswith(("drwxr", "-rwxr", "-rw-r")):
        continue
    seen[s] = seen.get(s, 0) + 1
for s, n in list(seen.items())[:60]:
    print("  x%-3d %s" % (n, s[:220]))

print("\n---- stall headers ----")
for l in lines:
    if "annibale: stall" in l and "stall frames" not in l and "stall pc" not in l:
        print("  ", l.strip()[:220])

print("\n---- crash reports ----")
for i, l in enumerate(lines):
    if '"bug_type"' in l:
        m = re.search(r'"name":"([^"]+)"', l)
        print("  report:", m.group(1) if m else "?", "| line", i)
        for j in range(i, min(i + 60, len(lines))):
            if '"termination"' in lines[j]:
                print("     ", lines[j].strip()[:400])
                break
