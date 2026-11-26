#!/usr/bin/env python3
"""s215 verdict: K90 new unlock dylib -> does SpringBoard enter desktop rendering?"""
import sys, re
p = sys.argv[1]
d = open(p, "rb").read().decode("utf-8", "replace")
lines = d.splitlines()
print("file=%s  bytes=%d  lines=%d" % (p, len(d), len(lines)))

def cnt(pat):
    rx = re.compile(pat)
    return sum(1 for l in lines if rx.search(l))

# panic
panic = cnt(r"panic|KERNEL FAULT|SoCReconfigured|abort\(\)")
print("PANIC_TOTAL=%d" % panic)
for l in lines:
    if re.search(r"panic|KERNEL FAULT", l, re.I):
        print("  PANIC>", l[:200])

# kernel pac (should be 0 pages since pac_patch=0 from s208)
pg = [l for l in lines if "pac: page" in l or "pac: pages=" in l]
print("PAC pages lines=%d" % len(pg))
if pg: print("  last:", pg[-1][:180])

# --- HARD verdict: SpringBoard desktop rendering ---
print("\n=== desktop render evidence ===")
sb = [l for l in lines if re.search(r"SpringBoard\[\d+\]", l)]
print("SpringBoard[N] lines = %d" % len(sb))
rp = [l for l in lines if "render pipelines" in l.lower() or "render_pipelines" in l.lower()]
print("render pipelines lines = %d" % len(rp))
for l in rp[-6:]: print("  RP>", l[:200])

unlock = cnt(r"unlockUIFromSource|unlockedEnvironmentMode")
print("unlockUIFromSource/unlockedEnvironmentMode = %d" % unlock)
for l in lines:
    if re.search(r"unlockUIFromSource|unlockedEnvironmentMode", l):
        print("  UNLOCK>", l[:200]); break

# activation noise (Unactivated)
unact = cnt(r"Code=-8|Device is not activated|Unactivated|Failed to copy activation record")
print("activation-unactivated noise lines = %d" % unact)

# wallclock range
wc = [l for l in lines if re.search(r"\b0[0-9]:[0-5]\d:[0-5]\d", l)]
print("wallclock-tagged lines = %d" % len(wc))
if wc:
    print("  first:", wc[0][:120])
    print("  last :", wc[-1][:120])

# sb26 dylib markers via kern.annibale.say
sb26 = [l for l in lines if "sb26:" in l or "annibale.say" in l]
print("sb26/sysctl lines = %d" % len(sb26))
for l in sb26[:12]: print("  SB26>", l[:180])

# key processes
for proc in ["SpringBoard", "backboardd", "mobileactivationd", "lsd", "backboardd", "PosterBoard"]:
    print("%-20s lines=%d" % (proc, cnt(re.escape(proc))))
