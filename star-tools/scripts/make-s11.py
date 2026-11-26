#!/usr/bin/env python3
"""s11 = s10 with one cmdline change: fb_dcs=0 fb_dim=0 fb_flip=0.

Why: the stage-9 kernel (s10) gets past the kalloc validation that stopped every
earlier build, then wedges the phone inside the first second -- the loader's USB
endpoint stops answering and the heartbeat never returns, so no log gets out.

The one hardware-touching thing this kernel does early is the display stack.
MiniFramebufferDCS.inc ships TUNABLE(gDcs, "fb_dcs", DCS_DEFAULT) with
DCS_DEFAULT = 4, and MiniFramebufferFlip.inc then writes gcc_disp_ahb_clk and
mdss_gdsc at *DPU 12.0 (SM8750) offsets* -- on star those addresses belong to a
different block, and the USB PHY's clock domain is next door.  s8's log caught it
doing exactly that write two lines before USB died.

With all three at 0, flip_start() returns on its first line, before
ml_io_map(0x0ae00000) -- the "no DPU register is touched" contract.

No rebuild: same kernel, same loader, same ramdisk, cmdline only.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s11"
PARTS = BASE + "/parts"
PREV = "/root/star26/s10/parts"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s11-payload.bin"
OUT_BOOT = BASE + "/s11-boot.img"
ASCII_OUT = "/mnt/c/ios26/s11-boot.img"

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
    print("=== 1. s10 parts, byte for byte ===")
    for name in SAME:
        a, b = os.path.join(PREV, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))
    assert b"STARSP" in open(os.path.join(PARTS, "kernel"), "rb").read()

    print("=== 2. cmdline: make the DPU code stand down ===")
    old = open(os.path.join(PREV, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert "fb_dcs" not in old
    new = old.rstrip() + " fb_dcs=0 fb_dim=0 fb_flip=0"
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
    print("  payload %d" % os.path.getsize(OUT_PAYLOAD))

    print("=== 4. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
