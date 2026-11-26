#!/usr/bin/env python3
"""s55 判读：WAITING 采样结果，定位 SpringBoard/backboardd 停住时的 PC/LR。

重点：wait N 行的帧（LR 是进入等待的调用者），以及是否仍 WAITING。
用法: python _an55.py /c/ios26/s55-staged.bin
"""
import re
import sys

p = sys.argv[1] if len(sys.argv) > 1 else "/c/ios26/s55-staged.bin"
data = open(p, "rb").read().decode("ascii", "replace").replace("\0", "")
lines = [l.rstrip() for l in data.split("\n")]
print("== %s (%d bytes, %d lines)" % (p, len(data), len(lines)))

print("\n---- wait 采样（WAITING 线程的 PC/LR/帧链）----")
seen = set()
for l in lines:
    if " wait " in l and "trace:" in l:
        s = l[l.index("trace:"):].strip()
        if s in seen:
            continue
        seen.add(s)
        print("  ", s[:300])

print("\n---- samp 采样（RUNNING，理论不该出现）----")
for l in lines:
    if " samp " in l and "trace:" in l and "wait" not in l:
        s = l[l.index("trace:"):].strip()
        print("  ", s[:200])

print("\n---- 心跳汇总（state 变化）----")
seen = set()
for l in lines:
    if " beat " in l and "trace:" in l:
        s = l[l.index("trace:"):].strip()
        # 只打印 state 有变化或首尾
        if s in seen:
            continue
        seen.add(s)
        print("  ", s[:220])

print("\n---- interposing / ctor 状态 ----")
for l in lines:
    if "interposing DISABLED" in l or "ctor pid=" in l or "ctor done" in l:
        print("  ", l.strip()[:200])
