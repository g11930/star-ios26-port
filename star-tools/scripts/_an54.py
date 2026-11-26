#!/usr/bin/env python3
"""s54 判读：干净 interposer 下 SpringBoard/backboardd 的真实行为。

重点：interposing 是否 DISABLED、心跳的 calls 计数、run_state、以及谁在等谁。
用法: python _an54.py /c/ios26/s54-staged.bin
"""
import re
import sys

p = sys.argv[1] if len(sys.argv) > 1 else "/c/ios26/s54-staged.bin"
data = open(p, "rb").read().decode("ascii", "replace").replace("\0", "")
lines = [l.rstrip() for l in data.split("\n")]
print("== %s (%d bytes, %d lines)" % (p, len(data), len(lines)))

print("\n---- trace: 时间线（去重）----")
seen = set()
for l in lines:
    if "trace: " not in l:
        continue
    s = l[l.index("trace: "):].strip()
    if s in seen:
        continue
    seen.add(s)
    print("  ", s[:240])

print("\n---- interposing 状态 ----")
for l in lines:
    if "interposing DISABLED" in l or "originals" in l:
        print("  ", l.strip()[:220])

print("\n---- 心跳（beat）汇总 ----")
for l in lines:
    if " beat " in l and "trace:" in l:
        s = l[l.index("trace:"):].strip()
        print("  ", s[:240])

print("\n---- 关键服务/选择子 ----")
for l in lines:
    if re.search(r"MiniIOMobileFramebuffer:|IOAcceleratorES|AnnibaleGPU|IOGPU|IOServiceMatching", l):
        print("  ", l.strip()[:200])

print("\n---- persona / kpersona ----")
for l in lines:
    if "persona" in l.lower() and "trace" not in l.lower():
        print("  ", l.strip()[:200])

print("\n---- launchd / SpringBoard / backboardd 进程线索 ----")
for l in lines:
    if re.search(r"launchd.*(SpringBoard|backboardd|uncorking)|SpringBoard.*(exec|spawn|launchd)|backboardd.*(exec|spawn)", l):
        print("  ", l.strip()[:220])
