#!/usr/bin/env python3
"""s7 = s6 + the display/GPU ABI layer (stage 7 / 7b), package only.

What changes versus s6
----------------------
kernel       11,545,504 -> 11,673,120 bytes: MiniIOSurface, IOMobileFramebuffer
             (`disp0`), AnnibaleGPU (stub mode) and their support files are
             now in the kernel, and GenericARMPE starts all three services.
cmdline      loader_return_after 45 -> 200.  45 s was chosen to reproduce
             p12's log window; it is far too early for WindowServer.  200 s
             keeps the controlled hand-back (p12's trick) while leaving the
             kernel enough time to bring the desktop up.  If the kernel's
             heartbeat never reaches the loader, SILENCE_SECONDS=50 still
             resets the phone -- so this cannot make things worse.

Everything else (loader.efi, ramdisk, rdimage, memsize, identity) is
byte-identical to s6, so `getvar build-id` still answers star-s5-stage6.

No device is touched by this script.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s7"
PARTS = BASE + "/parts"
PREV = "/root/star26/s6/parts"
KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s7-payload.bin"
OUT_BOOT = BASE + "/s7-boot.img"
ASCII_OUT = "/mnt/c/ios26/s7-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity")
OLD_CMD = "loader_return_after=45"
NEW_CMD = "loader_return_after=200"


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

    print("=== 1. kernel: the one part that must change ===")
    assert os.path.getsize(KERNEL) > 11_600_000, "kernel does not contain the display layer"
    shutil.copyfile(KERNEL, os.path.join(PARTS, "kernel"))
    raw = open(KERNEL, "rb").read()
    for marker in (b"IOMobileFramebuffer", b"disp0", b"IOCoreSurfaceRoot",
                   b"stub service registered", b"0xfc800000"):
        n = raw.count(marker)
        want = 0 if marker == b"0xfc800000" else 1
        assert (n >= want) if want else (n == 0), \
            "kernel marker %r: %d" % (marker, n)
        print("  %-28s %d" % (marker.decode(), n))
    print("  kernel %d bytes sha256 %s" % (os.path.getsize(KERNEL), sha(KERNEL)[:16]))

    print("=== 2. the rest is byte-identical to s6 ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b), "copy mismatch on " + name
        print("  %-10s %10d bytes  sha256 %s  (same as s6)" %
              (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 3. cmdline: longer return window, nothing else ===")
    old = open(os.path.join(PREV, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert OLD_CMD in old and "-v" not in old.split()
    new = old.replace(OLD_CMD, NEW_CMD)
    assert len(new) <= 1023
    open(os.path.join(PARTS, "cmdline"), "wb").write(new.encode("ascii") + b"\0")
    print("  %d bytes: %s" % (len(new), new))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 4. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", new, "--memsize", memsize, "--identity", identity])
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000, "PAYLOAD_CAP exceeded"
    print("  payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== 5. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
