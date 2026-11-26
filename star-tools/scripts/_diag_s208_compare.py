#!/usr/bin/env python3
# 只读对比多份 s208 staged 日志的进桌面判据，定位回滚后到底卡在哪
import re, sys

FILES = [
    "/mnt/c/ios26/s208-now.bin",              # 02:26 之前认定进桌面
    "/mnt/c/ios26/s208-rollback-053000.bin",  # 05:30 回滚中间态
    "/mnt/c/ios26/s208-final-054514.bin",     # 05:45 回滚晚态
    "/mnt/c/ios26/now-054802.bin",            # 05:48 刚抓最新
]

KEYS = [
    # unlock 链
    ("unlock", "unlockedEnvironmentMode"),
    ("unlock", "unlockUIFromSource"),
    ("unlock", "sb26: unlock"),
    ("unlock", "boot unlock"),
    ("unlock", "THE LOCK SCREEN STAYS"),
    ("unlock", "fDeviceFirstUnlocked:1"),
    ("unlock", "fDeviceLocked:0"),
    # SpringBoard / UI
    ("UI", "SpringBoard[33"),
    ("UI", "SpringBoard"),
    ("UI", "persona"),
    ("UI", "Setup"),
    ("UI", "poster"),
    ("UI", "snapshot"),
    # activation
    ("act", "activation_installed"),
    ("act", "setupActivationState"),
    ("act", "mobileactivationd"),
    ("act", "Code=-8"),
    ("act", "Unactivated"),
    # inject lib
    ("inject", "sb26: loaded"),
    ("inject", "software_icons_installed"),
    ("inject", "powerdown hooks"),
    # GPU / Metal
    ("gpu", "Metal"),
    ("gpu", "THE GPU STAYS"),
    ("gpu", "render pipelines"),
    ("gpu", "AnnibaleGPU"),
    # kernel
    ("kern", "panic"),
    ("kern", "PANIC"),
    ("kern", "pac: pages="),
    ("kern", "backboardd"),
]

def read(p):
    try:
        return open(p, "rb").read().decode("utf-8", "replace")
    except Exception as e:
        return None

def cmdline(d):
    m = re.search(r"^(?:cmdline|Command line|Kernel command line)\s*:?\s*(.+)$", d, re.M)
    if m:
        return m.group(1).strip()[:400]
    return "(none)"

def wallclock_range(d):
    ts = re.findall(r"\b(\d{2}:\d{2}:\d{2})\b", d)
    ts = [t for t in ts if t[:2] in ("00","01","02","03","04","05")]
    if not ts:
        return "(none)"
    return f"{min(ts)} -> {max(ts)}  (n={len(ts)})"

def pac_last(d):
    ls = [l for l in d.splitlines() if "pac: traps=" in l]
    return ls[-1].strip()[:120] if ls else "(none)"

data = {}
for p in FILES:
    d = read(p)
    data[p] = d
    print("=" * 100)
    print(p.split("/")[-1], "size=", len(d) if d else "MISSING")
    if d is None:
        continue
    print("  cmdline:", cmdline(d))
    print("  wallclock:", wallclock_range(d))
    print("  pac_last:", pac_last(d))

names = [p.split("/")[-1] for p in FILES]
print("\n" + "=" * 100)
print("KEY COUNTS")
print(f"{'key':<30} " + " ".join(f"{n[:14]:>14}" for n in names))
for grp, k in KEYS:
    vals = []
    for p in FILES:
        d = data[p]
        vals.append(str(d.count(k)) if d else "-")
    print(f"{grp+'/'+k:<30} " + " ".join(f"{v:>14}" for v in vals))

# focused: print unlock-related lines from the known-good sample
good = data[FILES[0]]
if good:
    print("\n" + "=" * 100)
    print("UNLOCK LINES IN s208-now.bin (known desktop sample):")
    for l in good.splitlines():
        if any(k in l for k in ("unlockedEnvironmentMode", "unlockUIFromSource", "sb26: unlock", "boot unlock")):
            print("  ", l.strip()[:200])
