#!/usr/bin/env python3
"""Verify the stage-0 star-native kernel is free of K90 platform drivers."""
import hashlib
import os

K = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
K90 = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"

b = open(K, "rb").read()
print("kernel      : %s" % K)
print("size        : %d bytes" % len(b))
print("md5         : %s" % hashlib.md5(b).hexdigest())
if os.path.exists(K90):
    k = open(K90, "rb").read()
    print("k90 size    : %d bytes / md5 %s" % (len(k), hashlib.md5(k).hexdigest()))
    print("same binary : %s" % (b == k))

MUST_BE_ABSENT = [
    b"the Adreno 830 of SM8750",
    b"DPU 12.0",
    b"0xfc800000",
    b"MiniIOMobileFramebuffer",
    b"MiniFramebufferFlip",
    b"SM8750 Iris VPU",
    b"SM8750 LPASS",
    b"star: SoC identity",          # P40 label patch must NOT have been carried
]
MUST_BE_PRESENT = [
    b"STAR_ARM64E_USERLAND",       # only a macro name; not expected in binary
    b"Software emulation of the FEAT_PAuth",
]
print("\n--- K90 strings (all must be 0) ---")
bad = 0
for s in MUST_BE_ABSENT:
    n = b.count(s)
    bad += n
    print("  %-42s %d" % (s.decode(), n))
print("\n--- star strings ---")
for s in [b"star stage-0 storage counters", b"annibale_ufs", b"arm64e"]:
    print("  %-42s %d" % (s.decode(), b.count(s)))
print("\nK90_RESIDUE=%d" % bad)
