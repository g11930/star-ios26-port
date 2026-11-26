#!/usr/bin/env python3
"""Symbolize the s82 kernel panic addresses against the built kernel."""
import bisect
import re
import subprocess

K = ("/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/"
     "mach.release.bcm2837.unstripped")
NM = "/root/star-build/xnu-deps/host/bin/nm"
ADDRS = [
    ("faulting pc", 0xFFFFFFF0071FBFF8),
    ("faulting lr", 0xFFFFFFF0071FBFC4),
    ("panic caller (abort path)", 0xFFFFFFF00788BE5C),
    ("panic caller (thread_invoke)", 0xFFFFFFF007233D08),
]

out = subprocess.run([NM, "-n", K], capture_output=True, text=True).stdout
syms = []
for line in out.splitlines():
    m = re.match(r"^\s*([0-9a-fA-F]{8,16})\s+[a-zA-Z?]\s+(.+)$", line)
    if m:
        syms.append((int(m.group(1), 16), m.group(2).strip()))
syms.sort()
keys = [s[0] for s in syms]
print("symbols:", len(syms), "first: 0x%x last: 0x%x" % (keys[0], keys[-1]))


def sym(addr):
    i = bisect.bisect_right(keys, addr) - 1
    if i < 0:
        return "<below first symbol>"
    b, n = syms[i]
    return "%s+0x%x" % (n, addr - b)


for label, v in ADDRS:
    print(f"0x{v:x}  {label}\n    -> {sym(v)}")
