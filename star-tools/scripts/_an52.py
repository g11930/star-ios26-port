#!/usr/bin/env python3
"""s52 判读：trace 库的时间线、IOMFB 选择子、进程表、崩溃文件。

用法: python _an52.py /c/ios26/s52-staged.bin
"""
import re
import sys

p = sys.argv[1] if len(sys.argv) > 1 else "/c/ios26/s52-staged.bin"
data = open(p, "rb").read().decode("ascii", "replace").replace("\0", "")
lines = [l.rstrip() for l in data.split("\n")]
print("== %s (%d bytes, %d lines)" % (p, len(data), len(lines)))

print("\n---- trace: 行（按出现顺序，去掉内核前缀重复）----")
seen_dup = set()
for l in lines:
    if "trace: " not in l:
        continue
    s = l[l.index("trace: "):].strip()
    if s in seen_dup:      # IOLog 把同一行打两遍（ring + console）
        continue
    seen_dup.add(s)
    print("  ", s[:220])

print("\n---- IOMobileFramebuffer 选择子 ----")
for l in lines:
    if "MiniIOMobileFramebuffer:" in l and ("selector" in l or "not implemented" in l):
        print("  ", l.strip()[:200])

print("\n---- 加速器 / GPU ----")
for l in lines:
    if re.search(r"IOAcceleratorES|AnnibaleGPU|IOGPU", l):
        print("  ", l.strip()[:200])

print("\n---- lsprobe ----")
for l in lines:
    s = l.strip()
    if "lsprobe t=" in s and ("procs=" in s or "cpu procs=" in s or "crash_files=" in s):
        print("  ", s[:250])

print("\n---- 崩溃报告名 ----")
for l in lines:
    if '"bug_type"' in l:
        m = re.search(r'"name":"([^"]+)"', l)
        print("   report:", m.group(1) if m else "?")

print("\n---- 最后 40 行 ----")
for l in [x for x in lines if x.strip()][-40:]:
    print("  ", l.strip()[:200])
