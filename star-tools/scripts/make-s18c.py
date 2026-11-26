#!/usr/bin/env python3
"""make-s18c.py <checkpoint>

Repack the *saved arm64* kernel (/root/star26/s18/parts/kernel, cpusubtype 0)
with an arbitrary checkpoint number.  Used to answer one question: does the
stage13/14/15 source state still reach checkpoint 1 (arm_vm_init) on arm64?

If yes -> the arm64 source tree is fine and the arm64e kernel has its own
          early-boot problem.
If no  -> the regression is in the source changes, not the architecture.

Everything except the kernel and the checkpoint number is identical to s18.
"""
import hashlib
import os
import shutil
import subprocess
import sys

CKPT = sys.argv[1] if len(sys.argv) > 1 else "1"

BASE = "/root/star26/s18"
PARTS = BASE + "/parts"
ARM64_KERNEL = "/root/star26/s18/parts/kernel"   # the saved arm64 kernel
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s18c-payload.bin"
OUT_BOOT = BASE + "/s18c-boot.img"
ASCII_OUT = "/mnt/c/ios26/s18c-boot.img"


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def run(argv):
    r = subprocess.run(argv, capture_output=True, text=True)
    if r.stdout.strip():
        print("    " + r.stdout.strip().replace("\n", "\n    "))
    if r.returncode != 0:
        print("    STDERR: " + r.stderr.strip())
        raise SystemExit("FAILED: exit %d" % r.returncode)


def main():
    print("=== kernel: saved arm64 build ===")
    kdst = os.path.join(PARTS, "kernel")
    print("  %d  %s" % (os.path.getsize(kdst), sha(kdst)[:16]))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("  cmdline (%d) checkpoint=%s" % (len(cmdline), CKPT))

    print("=== mkpayload --checkpoint %s ===" % CKPT)
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CKPT])

    print("=== reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
