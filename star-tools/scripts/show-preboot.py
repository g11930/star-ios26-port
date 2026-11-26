#!/usr/bin/env python3
"""Print the ignition / preboot parts of a staged log, plus the STAREDT diagnostic."""
import sys

p = sys.argv[1] if len(sys.argv) > 1 else "s29-staged.bin"
t = open(p, "rb").read().decode("utf-8", "replace").replace("\0", "")
print("staged bytes:", len(t))

print("\n=== STAREDT (our sysctl) ===")
found = False
for line in t.split("\n"):
    if "STAREDT" in line:
        print(line.strip()[:200])
        found = True
if not found:
    print("(none: the kernel never served edt_fstab, or the log ring lost it)")

print("\n=== ignition / preboot ===")
keys = ("ignition", "preboot", "Preboot", "fstab", "element size", "xART", "cryptex")
seen = []
for line in t.split("\n"):
    s = line.strip()
    if any(k in s for k in keys) and s not in seen:
        seen.append(s)
for s in seen[:60]:
    print(s[:220])
