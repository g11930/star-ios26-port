#!/usr/bin/env python3
# 时间序列：定位激活状态在哪一轮从"有效"翻转为"Unactivated"
import os

# (label, path) 按真实抓取时间排序
LOGS = [
    ("02:26 s208-now [进桌面]",        "/mnt/c/ios26/s208-now.bin"),
    ("04:06 s212-early",              "/mnt/c/ios26/now-040612.bin"),
    ("04:10 s212-mid",                "/mnt/c/ios26/now-041052.bin"),
    ("04:24 s212-late",               "/mnt/c/ios26/now-042429.bin"),
    ("04:25 s212-late2",              "/mnt/c/ios26/now-042536.bin"),
    ("05:03 s214-mid",                "/mnt/c/ios26/s214-mid-050309.bin"),
    ("05:18 s214-late",               "/mnt/c/ios26/s214-late-051823.bin"),
    ("05:30 s208-rollback",           "/mnt/c/ios26/s208-rollback-053000.bin"),
    ("05:45 s208-final",              "/mnt/c/ios26/s208-final-054514.bin"),
    ("05:48 s208-now-current",        "/mnt/c/ios26/now-054802.bin"),
]

def cnt(d, k):
    return d.lower().count(k.lower())

print(f"{'log':<28} {'Unact':>6} {'actRecFail':>10} {'unlockEnv':>9} {'unlockUI':>8} {'SB[33':>6} {'render':>6} {'setupNotDone':>12}")
print("-"*95)
for label, p in LOGS:
    if not os.path.exists(p):
        print(f"{label:<28} MISSING")
        continue
    d = open(p, "rb").read().decode("utf-8", "replace")
    print(f"{label:<28} "
          f"{cnt(d,'Unactivated'):>6} "
          f"{cnt(d,'Failed to copy activation record'):>10} "
          f"{cnt(d,'unlockedEnvironmentMode'):>9} "
          f"{cnt(d,'unlockUIFromSource'):>8} "
          f"{cnt(d,'SpringBoard[33'):>6} "
          f"{cnt(d,'render pipelines:'):>6} "
          f"{cnt(d,'Setup is not completed'):>12}")
