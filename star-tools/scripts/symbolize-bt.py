#!/usr/bin/env python3
"""symbolize-bt.py <staged.bin> -- symbolize a panic backtrace from a staged log."""
import bisect
import re
import subprocess
import sys

LOG = sys.argv[1]
K = ("/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/"
     "mach.release.bcm2837.unstripped")
NM = "/root/star-build/xnu-deps/host/bin/nm"

data = open(LOG, "rb").read().decode("utf-8", "replace").replace("\0", "")
start = data.rfind("--- panic buffer ---")
section = data[start:] if start >= 0 else data

out = subprocess.run([NM, "-n", K], capture_output=True, text=True).stdout
syms = []
for line in out.splitlines():
    m = re.match(r"^\s*([0-9a-fA-F]{8,16})\s+[a-zA-Z?]\s+(.+)$", line)
    if m:
        syms.append((int(m.group(1), 16), m.group(2).strip()))
keys = [s[0] for s in syms]


def sym(addr):
    i = bisect.bisect_right(keys, addr) - 1
    if i < 0:
        return "<below first symbol>"
    base, name = syms[i]
    return "%s +0x%x" % (name, addr - base)


print("symbols: %d   log: %s" % (len(syms), LOG))

for label, pat in (("pc", r"pc:\s+0x([0-9a-f]+)"),
                   ("lr", r"lr:\s+0x([0-9a-f]+)"),
                   ("far", r"far:\s+0x([0-9a-f]+)")):
    m = re.search(pat, section)
    if m:
        a = int(m.group(1), 16)
        print("  %-4s 0x%016x  %s" % (label, a, sym(a)))

print("\n--- backtrace LRs (from the clean panic buffer) ---")
lrs = [int(x, 16) for x in re.findall(r"lr:\s+0x([0-9a-f]+)", section)]
for a in lrs:
    print("  0x%016x  %s" % (a, sym(a)))

print("\n--- all kernel VAs in the panic buffer ---")
seen = set()
for m in re.finditer(r"0x([0-9a-fA-F]+)", section):
    a = int(m.group(1), 16)
    if 0xfffffff007000000 <= a < 0xfffffff009000000 and a not in seen:
        seen.add(a)
        print("  0x%016x  %s" % (a, sym(a)))
