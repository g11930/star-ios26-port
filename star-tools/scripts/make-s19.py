#!/usr/bin/env python3
"""s19 = the arm64e kernel (first build that actually compiles as arm64e).

What changed vs s18:
  * build-star-native.sh: ARCH_STRING_FOR_CURRENT_MACHINE_CONFIG=arm64e and
    XNU_TARGET_TRIPLE=arm64e-apple-ios16.5.  The clang wrapper had pinned
    `-target arm64-apple-ios16.5`, so `-arch arm64e` never reached the front end
    and the objects stayed plain arm64 (verified: kern_exec.o cpusubtype 0).
    Now every object is cpusubtype 2 and __arm64e__ is defined.
  * loader_return.c: stubs for the firehose symbols the firehose kext would
    provide.  With -arch arm64 they landed in the GOT as weak imports; arm64e
    emits a direct branch to address 0 and ld fails with "branch out of range".
  * kalloc.c: section constants re-measured for the new layout (stage 8 PASS).

Payload otherwise identical to s10/s18.  First boot uses checkpoint 1 --
arm_vm_init()'s first line -- because arm64e is a fresh variable: if that hits,
the arm64e kernel reaches its first C code at all.
"""
import hashlib
import os
import shutil
import subprocess
import sys

CKPT = sys.argv[1] if len(sys.argv) > 1 else "1"

BASE = "/root/star26/s19"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s19-payload.bin"
OUT_BOOT = BASE + "/s19-boot.img"
ASCII_OUT = "/mnt/c/ios26/s19-boot.img"

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

    print("=== 1. s10 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. the arm64e kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    assert b"STARX %s a=%lld b=%lld" in blob, "STARX format string missing"
    for tag in (b"LIP_ENTER", b"LIPA_EXEC", b"LM_PARSE", b"AES_ENTRY", b"EAI_EXIT"):
        assert tag in blob, "tag %r missing" % tag
    import struct
    m, ct, cs = struct.unpack_from("<Iii", blob, 0)
    assert (cs & 0xffffff) == 2, "kernel is not arm64e (cpusubtype %#x)" % (cs & 0xffffffff)
    print("  kernel %d  %s  cpusubtype %#x (arm64e)"
          % (os.path.getsize(kdst), sha(kdst)[:16], cs & 0xffffffff))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "checkpoint" not in cmdline, "checkpoint belongs in the payload, not the cmdline"
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload --checkpoint %s ===" % CKPT)
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CKPT])
    print("  payload %d" % os.path.getsize(OUT_PAYLOAD))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
