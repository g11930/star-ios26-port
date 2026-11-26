#!/usr/bin/env python3
"""s9 = s8 + two cmdline-only changes, both forced by what s8 exposed.

1) fb_dcs / fb_dim / fb_flip -> 0
   MiniFramebufferDCS.inc ships `TUNABLE(gDcs, "fb_dcs", DCS_DEFAULT)` with
   DCS_DEFAULT = 4, so the K90 display-controller code runs unless it is told
   not to.  The s8 log showed it doing exactly that:
       MiniIOMobileFramebuffer: flip: gcc_disp_ahb_clk 00000000 -> 00000001
       MiniIOMobileFramebuffer: flip: mdss_gdsc 00000000 (off)
   Those offsets are DPU 12.0 (SM8750).  star's MDSS is DPU at a different
   generation, so writing them is writing unknown registers.  flip_start()
   returns on its first line once all three are 0, before ml_io_map(0x0ae00000)
   -- that is the "no DPU register is touched" contract we promised.

2) -v
   With the kernel alive, USB dies within seconds (s8: `result: running`,
   then every get_staged hung).  So the only trustworthy channel is the panel.
   -v sets boot_args->Video.v_display = 0, XNU takes kPETextMode and paints its
   own console into 0xEA600000 -- that is what worked in s3, and it needs no
   USB and no loader cooperation.

Everything else is byte-identical to s8.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s9"
PARTS = BASE + "/parts"
PREV = "/root/star26/s8/parts"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s9-payload.bin"
OUT_BOOT = BASE + "/s9-boot.img"
ASCII_OUT = "/mnt/c/ios26/s9-boot.img"

SAME = ("loader.efi", "kernel", "ramdisk", "rdimage", "memsize", "identity")


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
    print("=== 1. every part identical to s8 ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. cmdline: stop the K90 DPU code, put the kernel text console back ===")
    old = open(os.path.join(PREV, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "-v" not in old.split()
    new = old.rstrip() + " fb_dcs=0 fb_dim=0 fb_flip=0 -v"
    assert len(new) <= 1023
    open(os.path.join(PARTS, "cmdline"), "wb").write(new.encode("ascii") + b"\0")
    print("  old (%d): %s" % (len(old), old))
    print("  new (%d): %s" % (len(new), new))

    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")

    print("=== 3. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", new, "--memsize", memsize, "--identity", identity])
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000
    print("  payload %d  %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)[:16]))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)[:16]))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
