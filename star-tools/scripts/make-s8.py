#!/usr/bin/env python3
"""s8 = s7 + the kalloc section constants re-measured for the larger kernel.

s7 reached `result: running` for 48 s and then panicked at
_kalloc_type_view_copy +0xe8 (esr=0x96000006, read translation fault) -- the
same instruction as s1.  Cause: stage 7 added ~127 KB of display code, which
moved __DATA_CONST, while osfmk/kern/kalloc.c still named s1's offsets.

stage 8 reads the offsets out of the linked kernel and writes them in; the
build script now gates on it, so this cannot go stale silently again.

Only `kernel` changes versus s7; cmdline stays at loader_return_after=200 so a
surviving kernel still hands back for a full log read.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s8"
PARTS = BASE + "/parts"
PREV = "/root/star26/s7/parts"
KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s8-payload.bin"
OUT_BOOT = BASE + "/s8-boot.img"
ASCII_OUT = "/mnt/c/ios26/s8-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline")


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

    print("=== 1. kernel: kalloc constants now match this build ===")
    shutil.copyfile(KERNEL, os.path.join(PARTS, "kernel"))
    raw = open(KERNEL, "rb").read()
    for marker in (b"IOMobileFramebuffer", b"disp0", b"star: brightness request refused"):
        assert marker in raw, "missing marker %r" % marker
        print("  %-34s %d" % (marker.decode(), raw.count(marker)))
    print("  kernel %d bytes sha256 %s" % (os.path.getsize(KERNEL), sha(KERNEL)[:16]))

    print("=== 2. the rest is byte-identical to s7 ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b), "copy mismatch on " + name
        print("  %-10s %10d bytes  sha256 %s  (same as s7)" %
              (name, os.path.getsize(b), sha(b)[:16]))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))

    print("=== 3. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity])
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000, "PAYLOAD_CAP exceeded"
    print("  payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
