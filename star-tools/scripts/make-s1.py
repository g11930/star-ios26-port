#!/usr/bin/env python3
"""s1 = first real flash of the star-native tree (baseline, NOT a desktop boot).

This is the "one cold boot" the user approved on 2026-11-15.  It answers three
questions on the real phone and nothing else:
  1. does the star-native kernel boot and mount a root volume at all
     (StarDisk.cpp / annibale_ufs_init from stage 1 have never run on hardware);
  2. does the loader's corrected fb_base=0xEA600000 keep the boot UI, progress
     bar and KERNEL BOOT CONSOLE card visible (stage 3's contract);
  3. what does the read-only SM8350 display survey read back
     (star_display_probe=1, zero register writes).

What is deliberately reused from P30 (the archived K90 line) as REFERENCE
ONLY: rdimage (flashboot.apfs, md0), ramdisk/root.apfs (the iOS26 helper
ramdisk incl. the SoC-independent Mesa softpipe userland), memsize, identity.
No SM8750 kernel driver is present: `kernel` is the freshly built star-native
mach.release.bcm2837.  `loader.efi` is rebuilt from the current loader source,
which carries the star framebuffer truth and the star milestone anchors.

cmdline changes vs P30, all explained:
  - drop `adreno8=2 adreno8_only=2` (no adreno8 driver exists in this tree)
  - `loader_return_after=420` -> 120 (baseline; get the log back sooner)
  - add `star_display_probe=1` (the single new variable under test)
  - keep `rwa_software=1 autounlock=1` (route A: soft-rendering userland)

Nothing is flashed by this script; it only writes an image.
"""
import hashlib
import os
import shutil
import subprocess
import sys

BASE = "/root/star26/s1"
PARTS = BASE + "/parts"
P30 = "/root/star26/p30/parts"
LDR_SRC = "/root/star26/hackios-xnu-kernel/xnuloader"
KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = LDR_SRC + "/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/s1-payload.bin"
OUT_BOOT = BASE + "/s1-boot.img"
ASCII_OUT = "/mnt/c/ios26/s1-boot.img"

P30_CMD = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 "
           "cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
           "loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1 autounlock=1")
CMD = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 "
       "cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
       "loader_return_after=120 rwa_software=1 autounlock=1 star_display_probe=1")


def run(argv, cwd=None):
    r = subprocess.run(argv, cwd=cwd, capture_output=True, text=True)
    if r.stdout.strip():
        print("    " + r.stdout.strip().replace("\n", "\n    "))
    if r.returncode != 0:
        print("    STDERR: " + r.stderr.strip())
        raise SystemExit("FAILED: %s (exit %d)" % (" ".join(argv[:3]), r.returncode))


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()[:16]


def main():
    os.makedirs(PARTS, exist_ok=True)
    print("=== 1. rebuild loader.efi from the patched star source ===")
    run(["clang", "--target=aarch64-unknown-windows", "-ffreestanding",
         "-fno-builtin", "-fno-stack-protector", "-fshort-wchar",
         "-mgeneral-regs-only", "-O1", "-Wall", "-Wextra", "-Wno-unused-parameter",
         "-DDIRECT_PHONE_PLAT", "-DPHONE_PLATFORM_STAR",
         "-c", "loader.c", "-o", BASE + "/loader.obj"], cwd=LDR_SRC)
    run(["lld-link", "/subsystem:efi_application", "/entry:efi_main",
         "/nodefaultlib", "/base:0xA1000000", "/out:" + BASE + "/loader.efi",
         BASE + "/loader.obj"], cwd=LDR_SRC)
    ldr = BASE + "/loader.efi"
    assert os.path.getsize(ldr) > 100000
    print("    loader.efi %d bytes sha256 %s" % (os.path.getsize(ldr), sha(ldr)))

    print("=== 2. assemble parts (reference userland, star kernel/loader) ===")
    for name in ("ramdisk", "rdimage", "memsize", "identity"):
        shutil.copyfile(os.path.join(P30, name), os.path.join(PARTS, name))
    shutil.copyfile(KERNEL, os.path.join(PARTS, "kernel"))
    shutil.copyfile(ldr, os.path.join(PARTS, "loader.efi"))
    with open(os.path.join(PARTS, "cmdline"), "wb") as fh:
        fh.write(CMD.encode("ascii") + b"\0")
    with open(os.path.join(PARTS, "cmdline"), "rb") as fh:
        assert fh.read().split(b"\0", 1)[0].decode() == CMD
    assert len(CMD) < 1023
    print("    cmdline (%d bytes): %s" % (len(CMD), CMD))
    print("    baseline P30 cmdline was: %s" % P30_CMD)
    for name in ("kernel", "loader.efi", "ramdisk", "rdimage"):
        p = os.path.join(PARTS, name)
        print("    %-10s %10d bytes  sha256 %s" % (name, os.path.getsize(p), sha(p)))

    print("=== 3. mkpayload ===")
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + os.path.join(PARTS, "kernel"),
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", CMD,
         "--memsize", open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode(),
         "--identity", open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode()])
    print("    payload %d bytes sha256 %s" % (os.path.getsize(OUT_PAYLOAD), sha(OUT_PAYLOAD)))
    assert os.path.getsize(OUT_PAYLOAD) <= 0x03700000, "PAYLOAD_CAP exceeded"

    print("=== 4. reseal into a bootable image ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("    %s %d bytes sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))

    os.makedirs(os.path.dirname(ASCII_OUT), exist_ok=True)
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("    ASCII copy: %s (%d bytes)" % (ASCII_OUT, os.path.getsize(ASCII_OUT)))
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
