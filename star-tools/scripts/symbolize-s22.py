#!/usr/bin/env python3
"""Symbolize the s22 kernel panic against the unstripped star-native kernel.

Reads the clean '--- panic buffer ---' section of the staged log (the earlier
copy has every character doubled by two interleaved writers), collects every
kernel VA, and maps each to the nearest preceding symbol.
"""
import bisect
import re
import subprocess

K = ("/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/"
     "mach.release.bcm2837.unstripped")
LOG = "/mnt/c/ios26/s22-staged.bin"
NM = "/root/star-build/xnu-deps/host/bin/nm"

data = open(LOG, "rb").read().decode("utf-8", "replace").replace("\0", "")
start = data.find("--- panic buffer ---")
end = data.find("== END OF LOG ==", start)
if end < 0:
    end = len(data)
section = data[start:end] if start >= 0 else data

# keep addresses in the kernel text/static range, ignore tiny values
addrs = []
for m in re.finditer(r"0x([0-9a-fA-F]+)", section):
    v = int(m.group(1), 16)
    if 0xfffffff000000000 <= v < 0xfffffff100000000 and v not in addrs:
        addrs.append(v)

out = subprocess.run([NM, "-n", K], capture_output=True, text=True).stdout
syms = []
for line in out.splitlines():
    m = re.match(r"^\s*([0-9a-fA-F]{8,16})\s+[a-zA-Z?]\s+(.+)$", line)
    if m:
        syms.append((int(m.group(1), 16), m.group(2).strip()))
print("symbols: %d, addresses to resolve: %d" % (len(syms), len(addrs)))
if not syms:
    raise SystemExit("nm produced no symbols")

keys = [s[0] for s in syms]


def sym(addr):
    i = bisect.bisect_right(keys, addr) - 1
    if i < 0:
        return "<below first symbol>"
    base, name = syms[i]
    return "%s +0x%x" % (name, addr - base)


print("\n--- key registers ---")
for label, addr in (
    ("pc", 0xfffffff00787c058),
    ("lr", 0xfffffff007781014),
    ("panic caller", 0xfffffff0078771d8),
    ("far", 0x27c74041),
    ("x21", 0x27c74029),
    ("x24", 0xfffffff008cea000),
    ("x25", 0xfffffff0070b7b1a),
    ("saved state", 0xfffffff3a8e273e0),
):
    print("  %-14s 0x%016x  %s" % (label, addr, sym(addr)))

print("\n--- backtrace (in order) ---")
bt = [
    0xfffffff0071fe274, 0xfffffff0073494a4, 0xfffffff007339d98,
    0xfffffff007338ddc, 0xfffffff007338640, 0xfffffff0071fd83c,
    0xfffffff0071fe808, 0xfffffff00786d110, 0xfffffff0078771d8,
    0xfffffff0073397b0, 0xfffffff007338640, 0xfffffff00787c058,
    0xfffffff007781014, 0xfffffff007782544, 0xfffffff007780097,
    0xfffffff007780c90, 0xfffffff00721c140, 0xfffffff00721c0a4,
    0xfffffff0078519e0, 0xfffffff0072372e8, 0xfffffff00733e60c,
]
for a in bt:
    print("  0x%016x  %s" % (a, sym(a)))

print("\n--- all other kernel VAs seen in the panic buffer ---")
for a in addrs:
    if a not in bt and a not in (0xfffffff00787c058, 0xfffffff007781014,
                                 0xfffffff0078771d8, 0xfffffff008cea000,
                                 0xfffffff0070b7b1a):
        print("  0x%016x  %s" % (a, sym(a)))
