#!/usr/bin/env python3
"""_s73_sym.py -- resolve s73 probe we/wq addresses against kernel symbols."""
import bisect
import re
import subprocess

K = ("/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/"
     "mach.release.bcm2837.unstripped")
NM = "/root/star-build/xnu-deps/host/bin/nm"
ADDRS = [
    ("bbd/SB T#0 event (turnstile wait)", 0xfffffff007008f30),
    ("bbd/SB/launchd shared sem event",   0xfffffff00700972c),
    ("launchd T#0 event",                 0xfffffff46097c488),
    ("launchd T#1 event",                 0xfffffff6c6eeffc8),
    ("service-port turnstile waitq",      0xfffffff62d620a00),
    ("bbd T#1 semaphore waitq",           0xfffffff4fa3344d0),
    ("launchd T#0 global waitq elem",     0xfffffff7f44c0c20),
    ("launchd T#1 global waitq elem",     0xfffffff7f44c0ba8),
]

out = subprocess.run([NM, "-n", K], capture_output=True, text=True).stdout
syms = []
for line in out.splitlines():
    m = re.match(r"^\s*([0-9a-fA-F]{8,16})\s+[a-zA-Z?]\s+(.+)$", line)
    if m:
        syms.append((int(m.group(1), 16), m.group(2).strip()))
syms.sort()
keys = [s[0] for s in syms]
print("symbols:", len(syms))
if keys:
    print("first symbol: 0x%x  last symbol: 0x%x" % (keys[0], keys[-1]))


def sym(addr):
    i = bisect.bisect_right(keys, addr) - 1
    if i < 0:
        return "<below first symbol>"
    b, n = syms[i]
    return "%s+0x%x" % (n, addr - b)


for label, v in ADDRS:
    print("0x%016x  %s\n    -> %s" % (v, label, sym(v)))
