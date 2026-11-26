#!/usr/bin/env python3
"""Compare libannibale-sb26.dylib: star current (s208 ramdisk) vs K90 v0.2.1 release vs star obj build."""
import struct, sys, os

PATHS = {
    "star-s208-ramdisk": "/tmp/s208rd/lib/libannibale-sb26.dylib",
    "star-obj-build":    "/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib",
    "k90-v021-release":  "/mnt/d/桌面/star26-deps/k90-ref/v021/hackios-k90-v0.2.1/root/lib/libannibale-sb26.dylib",
    "k90-v013-release":  "/mnt/d/桌面/star26-deps/release/hackios-k90-v0.1.3/root/lib/libannibale-sb26.dylib",
}

# markers indicating new (CoverSheet native) unlock flow vs old method-swizzling
MARKERS = [
    "waiting for the lock screen",
    "layout element",
    "appearState",
    "occlusion reasons",
    "boot unlock done",
    "activation call",
    "unlockUIFromSource",
    "unlock",
    "_setupActivationState",
    "23G90",
    "activation_installed",
    "sb26: loaded",
    "shouldForceBitmapImages",
    "CoverSheet",
]

# hardcoded activation hook address bytes: 0x22452fdc0 + slide; ADRP/ADD immediates vary,
# but the literal selector string and expected_bytes are stable
ADDR_LITERAL = struct.pack("<Q", 0x22452fdc0)
EXPECTED_BYTES = bytes.fromhex("08304039e80700377f2303d5ff4301d1")


def info(tag, p):
    if not os.path.exists(p):
        print("%-20s MISSING %s" % (tag, p)); return None
    d = open(p, "rb").read()
    magic = d[:4].hex()
    cpu, sub = struct.unpack_from("<II", d, 4) if magic == "cffaedfe" else (0, 0)
    print("\n=== %s ===" % tag)
    print("  path : %s" % p)
    print("  size : %d  magic=%s cputype=%s cpusubtype=%s" % (len(d), magic, hex(cpu), hex(sub)))
    print("  sha256: %s" % __import__("hashlib").sha256(d).hexdigest())
    print("  markers:")
    for m in MARKERS:
        print("    %-32s %d" % ('"'+m+'"', d.count(m.encode())))
    print("  addr literal 0x22452fdc0 as <Q : %d" % d.count(ADDR_LITERAL))
    print("  expected_bytes present        : %d" % d.count(EXPECTED_BYTES))
    return d


data = {}
for tag, p in PATHS.items():
    data[tag] = info(tag, p)

# byte-level comparison of star-current vs k90-v021
a, b = data.get("star-s208-ramdisk"), data.get("k90-v021-release")
if a and b:
    print("\n=== byte compare star-s208 vs k90-v021 ===")
    print("  sizes: %d vs %d  equal=%s" % (len(a), len(b), len(a) == len(b)))
    if len(a) == len(b):
        diff = [i for i in range(len(a)) if a[i] != b[i]]
        print("  identical=%s diff_bytes=%d" % (len(diff) == 0, len(diff)))
    else:
        # first divergence
        n = min(len(a), len(b))
        for i in range(n):
            if a[i] != b[i]:
                print("  first diff at %d: %02x vs %02x" % (i, a[i], b[i])); break
