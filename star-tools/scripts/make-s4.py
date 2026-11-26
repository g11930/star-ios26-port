#!/usr/bin/env python3
"""s4 = s3 + the stage-5 loader USB gate fix, and NOTHING else.

The kernel, ramdisk, rdimage, memsize, identity and cmdline (including `-v`)
are copied byte-for-byte from s3.  Only `loader.efi` is rebuilt from the
patched star loader source, so a single variable is under test: does masking
the firmware IRQ handlers before XNU re-programs the GIC keep fastboot alive
while the kernel runs (so `oem log` / `get_staged` / `oem screenshot` work)?

No device is touched by this script.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s4"
PARTS = BASE + "/parts"
S3 = "/root/star26/s3/parts"
LDR_SRC = "/root/star26/hackios-xnu-kernel/xnuloader"
MKPAYLOAD = LDR_SRC + "/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s4-payload.bin"
OUT_BOOT = BASE + "/s4-boot.img"
ASCII_OUT = "/mnt/c/ios26/s4-boot.img"

SAME = ("kernel", "ramdisk", "rdimage", "memsize", "identity", "cmdline")


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def run(argv, cwd=None):
    r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True)
    if r.stdout.strip():
        print("    " + r.stdout.strip().replace("\n", "\n    "))
    if r.returncode != 0:
        print("    STDERR: " + r.stderr.strip())
        raise SystemExit("FAILED: %s (exit %d)" % (" ".join(argv[:3]), r.returncode))


def main():
    os.makedirs(PARTS, exist_ok=True)

    print("=== 1. rebuild loader.efi from the stage-5 star source ===")
    run(["clang", "--target=aarch64-unknown-windows", "-ffreestanding",
         "-fno-builtin", "-fno-stack-protector", "-fshort-wchar",
         "-mgeneral-regs-only", "-O1", "-Wall", "-Wextra", "-Wno-unused-parameter",
         "-DDIRECT_PHONE_PLAT", "-DPHONE_PLATFORM_STAR",
         "-c", "loader.c", "-o", BASE + "/loader.obj"], cwd=LDR_SRC)
    run(["lld-link", "/subsystem:efi_application", "/entry:efi_main",
         "/nodefaultlib", "/base:0xA1000000", "/out:" + BASE + "/loader.efi",
         BASE + "/loader.obj"], cwd=LDR_SRC)
    ldr = BASE + "/loader.efi"
    assert os.path.getsize(ldr) > 100000
    old_ldr = os.path.join(S3, "loader.efi")
    assert sha(ldr) != sha(old_ldr), "loader.efi did not change"
    print("    loader.efi %d bytes sha256 %s (s3 was %s)" %
          (os.path.getsize(ldr), sha(ldr)[:16], sha(old_ldr)[:16]))

    print("=== 2. every other part must be byte-identical to s3 ===")
    for name in SAME:
        a, b = os.path.join(S3, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b), "copy mismatch on " + name
        print("  %-10s %10d bytes  sha256 %s  (same as s3)" %
              (name, os.path.getsize(b), sha(b)[:16]))
    shutil.copyfile(ldr, os.path.join(PARTS, "loader.efi"))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert cmdline.endswith(" -v"), "s4 must keep -v for on-panel kernel text"
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("  cmdline (%d bytes): %s" % (len(cmdline), cmdline))

    print("=== 3. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity])
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000, "PAYLOAD_CAP exceeded"
    print("  payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== 4. reseal into a bootable image ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
