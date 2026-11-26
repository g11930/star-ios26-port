#!/usr/bin/env python3
"""s56 判读：logd 崩溃前的高频 PC/LR 采样。

重点：logdtrace 行的 PC 演进（最后一次就是崩溃位置），以及 logd 是否仍 SIGTRAP 崩。
用法: python _an56.py /c/ios26/s56-staged.bin
"""
import re
import sys

p = sys.argv[1] if len(sys.argv) > 1 else "/c/ios26/s56-staged.bin"
data = open(p, "rb").read().decode("ascii", "replace").replace("\0", "")
lines = [l.rstrip() for l in data.split("\n")]
print("== %s (%d bytes, %d lines)" % (p, len(data), len(lines)))

print("\n---- logdtrace: 采样行（PC/LR 演进）----")
seen = set()
for l in lines:
    if "logdtrace:" in l:
        s = l.strip()
        if s in seen:
            continue
        seen.add(s)
        print("  ", s[:220])

print("\n---- logd 崩溃/退出证据 ----")
for l in lines:
    if re.search(r"logd.*(SIGTRAP|xstat 5|Corpse failure|exited due|P28EXIT)", l):
        print("  ", l.strip()[:180])

print("\n---- PAC 模拟状态 ----")
for l in lines:
    if "pac_emu" in l:
        print("  ", l.strip()[:200])

print("\n---- 心跳（确认 SpringBoard/backboardd 仍 runloop）----")
seen = set()
for l in lines:
    if " beat " in l and "trace:" in l:
        s = l[l.index("trace:"):].strip()
        if s in seen:
            continue
        seen.add(s)
        print("  ", s[:150])
