#!/usr/bin/env python3
"""Resolve the s1 panic addresses against the unstripped star-native kernel."""
import bisect
import re
import subprocess

K = ("/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/"
     "mach.release.bcm2837.unstripped")

ADDRS = {
    "pc":            0xfffffff007859e84,
    "lr":            0xfffffff00785a170,
    "panic caller":  0xfffffff0078631d4,
    "far":           0xfffffff0071d4a30,
    "x1/x21":        0xfffffff0071d4a08,
    "x2/x23":        0xfffffff0071e8888,
    "x3/x22":        0xfffffff008d4fd40,
    "x6":            0xfffffff008d4f920,
    "x16":           0xfffffff008d4f834,
    "x17":           0xfffffff008d4f820,
    "saved state":   0xfffffff008d57cb0,
}

NM = "/root/star-build/xnu-deps/host/bin/nm"   # cctools nm understands Mach-O
out = subprocess.run([NM, "-n", K], capture_output=True, text=True).stdout
syms = []
for line in out.splitlines():
    m = re.match(r"^\s*([0-9a-fA-F]{8,16})\s+[a-zA-Z?]\s+(.+)$", line)
    if m:
        syms.append((int(m.group(1), 16), m.group(2).strip()))
print("symbols: %d" % len(syms))
if not syms:
    raise SystemExit("nm produced no symbols")

keys = [s[0] for s in syms]
for label, addr in ADDRS.items():
    i = bisect.bisect_right(keys, addr) - 1
    if i < 0:
        print("  %-14s 0x%016x  <below first symbol>" % (label, addr))
        continue
    base, name = syms[i]
    nxt = syms[i + 1][0] if i + 1 < len(syms) else None
    span = (" next=+%d" % (nxt - addr)) if nxt else ""
    print("  %-14s 0x%016x  %s +0x%x%s" % (label, addr, name, addr - base, span))

# Print the symbol neighbourhood around far (the suspected write target).
print("\n--- symbols around far ---")
lo = bisect.bisect_left(keys, 0xfffffff0071d4000)
hi = bisect.bisect_right(keys, 0xfffffff0071d5000)
for base, name in syms[max(0, lo - 4):hi + 4]:
    print("  0x%016x  %s" % (base, name))
