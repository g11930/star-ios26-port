#!/usr/bin/env python3
"""make-s21.py [checkpoint]

P0 single-variable image: EXACTLY the s20 parts (loader, ramdisk, rdimage,
memsize, identity, cmdline, reference boot image, checkpoint) with only the
kernel replaced by the stage16 build (printf-free static/hex logging).

Keeping the cmdline byte-identical (including epoch and
loader_return_after=200) means any behavioural difference is attributable to
the kernel alone.  --checkpoint stays 14 so the result is directly comparable
to "result: checkpoint 14 0" from s20.
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys

CKPT = sys.argv[1] if len(sys.argv) > 1 else "14"

BASE = "/root/star26/s21"
PARTS = BASE + "/parts"
PREV = "/root/star26/s20/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s21-payload.bin"
OUT_BOOT = BASE + "/s21-boot.img"
ASCII_OUT = "/mnt/c/ios26/s21-boot.img"

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

    print("=== 1. s20 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. stage16 kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    magic, cputype, cpusub, ft, ncmds, sz, flags, res = struct.unpack_from("<IiiIIIII", blob, 0)
    sub = cpusub & 0xFFFFFFFF
    print("  size %d  cputype %#x  cpusubtype %#x" % (len(blob), cputype & 0xFFFFFFFF, sub))
    assert (sub & 0x00FFFFFF) == 0, "kernel is NOT plain arm64 (cpusubtype %#x)" % sub
    for tag in (b"STAR0: bsdinit_task alive", b"STAR0: log_len before=0x",
                b"STARL ", b"LIP_ENTER", b"LM_PARSE", b"AES_ENTRY"):
        assert tag in blob, "stage16 tag %r missing from kernel" % tag
    for dead in (b"STARX %s a=%lld b=%lld", b"STARX %s %s a=%lld"):
        assert dead not in blob, "old printf format string %r still in kernel" % dead
    print("  %s" % sha(kdst)[:16])

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("=== 3. cmdline (%d) %s" % (len(cmdline), cmdline))
    assert "checkpoint" not in cmdline, "checkpoint belongs in the payload"
    assert len(cmdline) < 1024, "cmdline exceeds BOOT_LINE_LENGTH"

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
