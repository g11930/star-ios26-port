#!/usr/bin/env python3
"""make-s20.py [checkpoint]

s20 = arm64 kernel (correct architecture) + STAR_ARM64E_USERLAND already built
in, with an `epoch=` boot arg and a checkpoint in the payload.

Why arm64: SM8350 has no FEAT_PAuth.  Both reference ports keep the kernel
arm64 and only *report* arm64e to user space (warsaw's REDWOOD_ARM64E_USERLAND,
and hakios-arm64e-dada's Oryon hardware-PAC build).  Our tree has the
equivalent STAR_ARM64E_USERLAND in pexpert/pexpert/arm64/BCM2837.h.

Everything is byte-identical to s10 except:
  - the kernel (freshly rebuilt as arm64, cpusubtype 0x0)
  - cmdline: + epoch=<unix time>, otherwise unchanged
  - payload: --checkpoint N

epoch is mandatory per warsaw's README: without it the kernel clock is wrong
and the clock service does not work.  Obtain it from the host clock, never
hardcode it.
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import time

CKPT = sys.argv[1] if len(sys.argv) > 1 else "14"

BASE = "/root/star26/s20"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s20-payload.bin"
OUT_BOOT = BASE + "/s20-boot.img"
ASCII_OUT = "/mnt/c/ios26/s20-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity")


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

    print("=== 1. s10 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. the rebuilt arm64 kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    magic, cputype, cpusub, ft, ncmds, sz, flags, res = struct.unpack_from("<IiiIIIII", blob, 0)
    sub = cpusub & 0xFFFFFFFF
    print("  size %d  cputype %#x  cpusubtype %#x" % (len(blob), cputype & 0xFFFFFFFF, sub))
    assert (sub & 0x00FFFFFF) == 0, "kernel is NOT plain arm64 (cpusubtype %#x)" % sub
    for tag in (b"STARX %s a=%lld b=%lld", b"LIP_ENTER", b"LM_PARSE", b"AES_ENTRY"):
        assert tag in blob, "tag %r missing" % tag
    print("  %s" % sha(kdst)[:16])

    print("=== 3. cmdline + epoch ===")
    orig = open(os.path.join(PREV, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "checkpoint" not in orig, "checkpoint belongs in the payload"
    epoch = int(time.time())
    cmdline = orig if "epoch=" in orig else (orig + " epoch=%d" % epoch)
    with open(os.path.join(PARTS, "cmdline"), "wb") as f:
        f.write(cmdline.encode("ascii") + b"\0")
    print("  (%d) %s" % (len(cmdline), cmdline))
    assert len(cmdline) < 1024, "cmdline exceeds BOOT_LINE_LENGTH"

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 4. mkpayload --checkpoint %s ===" % CKPT)
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CKPT])

    print("=== 5. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
