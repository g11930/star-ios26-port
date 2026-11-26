#!/usr/bin/env python3
"""s3 = s2 + a single `-v` boot-arg, so the kernel's text console is drawn
straight onto the 0xEA600000 splash framebuffer.

Why: after a healthy kernel takes over, the loader's USB/fastboot endpoint
dies, so `get_staged` and the logdump partition both stop producing the
current run's kernel log (s2).  With -v the loader sets
boot_args->Video.v_display = 0 and XNU calls
PE_initialize_console(..., kPETextMode); the kernel text then appears on the
panel itself -- readable from a photo, no USB needed.

Everything except cmdline is asserted byte-identical to s2.
"""
import hashlib
import os
import shutil
import subprocess
import sys

S2 = "/root/star26/s2/parts"
BASE = "/root/star26/s3"
PARTS = BASE + "/parts"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s3-payload.bin"
OUT_BOOT = BASE + "/s3-boot.img"
ASCII_OUT = "/mnt/c/ios26/s3-boot.img"


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
    print("=== s3 parts: only cmdline may differ from s2 ===")
    for name in ("kernel", "loader.efi", "ramdisk", "rdimage", "memsize", "identity"):
        a, b = os.path.join(S2, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        if sha(a) != sha(b):
            raise SystemExit("copy mismatch on " + name)
        print("  %-10s %10d bytes  sha256 %s  (same as s2)" %
              (name, os.path.getsize(b), sha(b)[:16]))

    old = open(os.path.join(S2, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "-v" not in old, "s2 cmdline already has -v"
    # A standalone token: the loader checks starts_with(c,"-v") and the next
    # character being a space or NUL.
    new = old + " -v"
    assert len(new) < 1023
    with open(os.path.join(PARTS, "cmdline"), "wb") as fh:
        fh.write(new.encode("ascii") + b"\0")
    print("  %-10s %10d bytes  (CHANGED)" % ("cmdline", len(new)))
    print("  old: %s" % old)
    print("  new: %s" % new)

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", new, "--memsize", memsize, "--identity", identity])
    print("  payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
