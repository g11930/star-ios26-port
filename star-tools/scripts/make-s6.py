#!/usr/bin/env python3
"""s6 = s5 with ONE variable changed: the cmdline.

Why: p12 (which reaches 76% and keeps the boot log visible) proves that the
loader return window must be SHORTER than the loader's silence watchdog.

  loader_return.c:690  STARTUP(EARLY_BOOT,RANK_LAST) timer -> loader_return()
  loader_02:424        SILENCE_SECONDS = 50  -> OTHER_CPU_HUNG -> cold reset

p12 uses loader_return_after=45  (45 < 50) => the kernel hands control back
before the watchdog fires => loader finishes cleanly, write_logs() flushes the
complete kernel log to the logdump / staged buffer, and fastboot is still
alive so `oem log` / `get_staged` / `oem screenshot` all work.

s3/s4/s5 used loader_return_after=120 (120 > 50) => the watchdog always fires
first, the phone cold-resets to Android and every log is lost.  That single
number explains the 58 s on-screen counter and the 55-84 s auto reboot.

Second change: drop `-v`.  loader_05:588-603 sets boot_args->video.v_display
from the presence of `-v`:
  no  -v  -> v_display = 1 (kPEGraphicsMode: kernel only maps the framebuffer,
             never clears it, never draws text -> loader UI stays intact)
  has -v  -> v_display = 0 (kPETextMode: kernel writes text into the SAME
             0xEA600000 buffer the loader repaints every ~2 s -> mutual
             overwrite / tearing, which is what s3/s4 showed)
p12 has no `-v`, so we drop it too -- single variable, back to p12's shape.

Everything else (loader.efi incl. build-id, kernel, ramdisk, rdimage, memsize,
identity) stays byte-identical to s5, so `getvar build-id` still answers
`star-s5-stage6` and we keep the identity proof from the s5 run.
No device is touched by this script.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s6"
PARTS = BASE + "/parts"
S5 = "/root/star26/s5/parts"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s6-payload.bin"
OUT_BOOT = BASE + "/s6-boot.img"
ASCII_OUT = "/mnt/c/ios26/s6-boot.img"

SAME = ("loader.efi", "kernel", "ramdisk", "rdimage", "memsize", "identity")

OLD_TAIL = "loader_return_after=120 rwa_software=1 autounlock=1 star_display_probe=1 -v"
NEW_TAIL = "loader_return_after=45 rwa_software=1 autounlock=1 star_display_probe=1"


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
    print("=== 1. every part except cmdline must be byte-identical to s5 ===")
    for name in SAME:
        a, b = os.path.join(S5, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b), "copy mismatch on " + name
        print("  %-10s %10d bytes  sha256 %s  (same as s5)" %
              (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. cmdline: the only change ===")
    old = open(os.path.join(S5, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    assert OLD_TAIL in old, "s5 cmdline does not end the way this script expects"
    new = old.replace(OLD_TAIL, NEW_TAIL)
    assert new != old and "-v" not in new.split()
    assert "loader_return_after=45" in new
    for tok in ("ufs=2", "ufs_native=1", "ufs_write=1", "root_apfs=ufs_darwin",
                "rwa_software=1", "autounlock=1", "star_display_probe=1"):
        assert tok in new, "required token lost: " + tok
    assert len(new) <= 1023, "cmdline exceeds BOOT_LINE_LENGTH"
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
