#!/usr/bin/env python3
"""s14 = the stage-10 checkpoint kernel, with the checkpoint passed the right way.

s12/s13 proved nothing: `checkpoint=9` / `checkpoint=1` were put in the *kernel
cmdline*, but the loader reads the checkpoint from a payload entry of that name
(parse_payload in loader_04_fault_payload_nvram.inc, pi->checkpoint).  The logdump
said so plainly -- "return slot patched at f733c7f0, checkpoint 0" -- while the
cmdline carried checkpoint=1.  So loader_stub_slot[2] stayed 0 and every
loader_checkpoint(n) call returned without jumping.

mkpayload.py has --checkpoint for exactly this.  Point 1 is
arm_vm_init()'s first line, the kernel's first C code:

  stops   -> the kernel reaches C; the fault is later, bisect upwards (9, 7, 5, 4, 3, 2)
  no stop -> the fault is in _start/arm_init, i.e. in the assembly before any C

Everything else is s10 (s7 cmdline, no fb_*, no -v).
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s14"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s14-payload.bin"
OUT_BOOT = BASE + "/s14-boot.img"
ASCII_OUT = "/mnt/c/ios26/s14-boot.img"
CHECKPOINT = sys.argv[1] if len(sys.argv) > 1 else "1"

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

    print("=== 2. the stage-10 kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    assert sha(kdst) != sha(os.path.join(PREV, "kernel")), "kernel unchanged"
    assert b"STARSP" in blob
    print("  kernel %d  %s" % (os.path.getsize(kdst), sha(kdst)[:16]))

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "checkpoint" not in cmdline, "checkpoint belongs in the payload, not the cmdline"
    print("  cmdline (%d): %s" % (len(cmdline), cmdline))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload with --checkpoint %s ===" % CHECKPOINT)
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CHECKPOINT])
    print("  payload %d" % os.path.getsize(OUT_PAYLOAD))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
