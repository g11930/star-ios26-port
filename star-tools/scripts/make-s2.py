#!/usr/bin/env python3
"""s2 = s1 with exactly one change: the kalloc-section-offset fix in the kernel.

s1 panicked before bsd_init because osfmk/kern/kalloc.c hardcoded the K90
kernel's __kalloc_type / __kalloc_var offsets.  stage4-kalloc-deltas.py
replaced them with the offsets measured on the star-native binary.

This script asserts that every other part (loader.efi, ramdisk, rdimage,
cmdline, memsize, identity) is byte-identical to s1, so the second flash
tests one variable and one variable only.
"""
import hashlib
import os
import shutil
import subprocess
import sys

S1 = "/root/star26/s1/parts"
BASE = "/root/star26/s2"
PARTS = BASE + "/parts"
KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s2-payload.bin"
OUT_BOOT = BASE + "/s2-boot.img"
ASCII_OUT = "/mnt/c/ios26/s2-boot.img"


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def run(argv):
    r = subprocess.run(argv, capture_output=True, text=True)
    if r.stdout.strip():
        print("    " + r.stdout.strip().replace("\n", "\n    "))
    if r.returncode != 0:
        print("    STDERR: " + r.stderr.strip())
        raise SystemExit("FAILED: %s (exit %d)" % (" ".join(argv[:3]), r.returncode))


def main():
    os.makedirs(PARTS, exist_ok=True)
    print("=== s2 parts: only the kernel may differ from s1 ===")
    for name in ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline"):
        a, b = os.path.join(S1, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        if sha(a) != sha(b):
            raise SystemExit("copy mismatch on " + name)
        print("  %-10s %10d bytes  sha256 %s  (same as s1)" %
              (name, os.path.getsize(b), sha(b)[:16]))
    shutil.copyfile(KERNEL, os.path.join(PARTS, "kernel"))
    print("  %-10s %10d bytes  sha256 %s  (CHANGED)" %
          ("kernel", os.path.getsize(os.path.join(PARTS, "kernel")),
           sha(os.path.join(PARTS, "kernel"))[:16]))
    old_kernel = os.path.join(S1, "kernel")
    if sha(old_kernel) == sha(os.path.join(PARTS, "kernel")):
        raise SystemExit("kernel did not change -- rebuild first")

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("  cmdline (%d bytes): %s" % (len(cmdline), cmdline))

    print("=== mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity])
    print("  payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
