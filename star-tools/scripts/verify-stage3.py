#!/usr/bin/env python3
"""Host-side static verification of star-native stage 3 (no flashing)."""
import hashlib
import re

K = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"

data = open(K, "rb").read()
strings = b"\n".join(re.findall(rb"[ -~]{6,}", data))

print("kernel: %s" % K)
print("size  : %d bytes" % len(data))
print("md5   : %s" % hashlib.md5(data).hexdigest())
print("sha256: %s" % hashlib.sha256(data).hexdigest()[:16] + "...")

present = [
    b"star_display: handoff base=0x%lx",
    b"star_display: boot-args video MATCHES the star panel",
    b"star_display: owner=loader; kernel does NOT clear",
    b"star: milestone %s",
    b"StarDisk: published",
    b"star: UFS LUN 0 measured",
    b"star_display: READ-ONLY survey",
]
absent = [
    b"0xfc800000",
    b"0xFC800000",
    b"DPU 12.0",
    b"MiniFramebufferFlip",
    b"MiniIOMobileFramebuffer",
    b"AnnibaleDiskStart",
    b"PMK8550",
    b"SM8750 Iris",
    b"the Adreno 830 of SM8750",
    b"star: SoC identity",
]

bad = 0
print("--- must be present ---")
for token in present:
    n = strings.count(token)
    ok = n >= 1
    bad += 0 if ok else 1
    print("  %-4s %-58s %d" % ("OK" if ok else "FAIL", token.decode(), n))
print("--- must be absent (K90 residue) ---")
for token in absent:
    n = strings.count(token)
    ok = n == 0
    bad += 0 if ok else 1
    print("  %-4s %-58s %d" % ("OK" if ok else "FAIL", token.decode(), n))

print("RESULT: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
raise SystemExit(0 if bad == 0 else 1)
