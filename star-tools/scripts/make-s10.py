#!/usr/bin/env python3
"""s10 = s7 exactly, with one variable changed: the kernel.

s7 is the only run whose kernel log we ever read (see 2026-11-15.md): it reached
`running`, kept USB alive for 48 s and handed over a staged log with a complete
panic in it.  So its cmdline, loader, ramdisk, rdimage, memsize and identity are
copied byte for byte -- no -v, no fb_* flags -- and only `kernel` is new:

  sleh.c now writes a STARSP line (sp/fp/pc/lr/cpsr/kstack top) straight into the
  loader's log ring before panic_plain prints the table that gets truncated at
  958 bytes, and the pac_emu notes go through the same path instead of printf(),
  which is stripped by CONFIG_NO_PRINTF_STRINGS.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s10"
PARTS = BASE + "/parts"
PREV = "/root/star26/s7/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s10-payload.bin"
OUT_BOOT = BASE + "/s10-boot.img"
ASCII_OUT = "/mnt/c/ios26/s10-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline")


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
    os.makedirs(PARTS, exist_ok=True)
    print("=== 1. everything but the kernel is s7, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. kernel: the stage-9 diagnostic build ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    assert sha(kdst) == sha(NEW_KERNEL)
    old = sha(os.path.join(PREV, "kernel"))
    print("  old s7 kernel %10d  %s" % (os.path.getsize(os.path.join(PREV, "kernel")), old[:16]))
    print("  new kernel    %10d  %s" % (os.path.getsize(kdst), sha(kdst)[:16]))
    assert old != sha(kdst), "kernel is unchanged -- the build did not pick the patch up"
    blob = open(kdst, "rb").read()
    assert b"STARSP #%llu sp=" in blob, "STARSP string is not in the kernel"
    print("  STARSP string present")

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))
    assert "-v" not in cmdline.split(), "s10 must stay comparable to s7: no -v"
    assert "fb_dcs" not in cmdline

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity])
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000
    print("  payload %d  %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
