#!/usr/bin/env python3
"""make-s23.py [checkpoint]

s23 = s22 + stage18 (pe_init.c printf neutralized).  Only the kernel differs;
every other part is byte-identical to s22/s21/s20.  checkpoint 114 =
bsd_init.c immediately before load_init_program().
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys

CKPT = sys.argv[1] if len(sys.argv) > 1 else "114"

BASE = "/root/star26/s23"
PARTS = BASE + "/parts"
PREV = "/root/star26/s22/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s23-payload.bin"
OUT_BOOT = BASE + "/s23-boot.img"
ASCII_OUT = "/mnt/c/ios26/s23-boot.img"

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

    print("=== 1. s22 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. stage18 kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    magic, cputype, cpusub, ft, ncmds, sz, flags, res = struct.unpack_from("<IiiIIIII", blob, 0)
    sub = cpusub & 0xFFFFFFFF
    print("  size %d  cputype %#x  cpusubtype %#x" % (len(blob), cputype & 0xFFFFFFFF, sub))
    assert (sub & 0x00FFFFFF) == 0, "kernel is NOT plain arm64"
    for tag in (b"STAR0: bsdinit_task alive", b"STARL ", b"LIP_ENTER", b"LM_PARSE"):
        assert tag in blob, "tag %r missing" % tag
    print("  %s" % sha(kdst)[:16])

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("=== 3. cmdline (%d) %s" % (len(cmdline), cmdline))
    assert len(cmdline) < 1024

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
