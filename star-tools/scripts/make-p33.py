#!/usr/bin/env python3
"""P33 = P32 + fbpaint=1 in the kernel arguments (a red panel at start).

Everything else is P32's: same loader.efi, rdimage, root.apfs (framewatch and the four unlock
notifications), memsize, identity. The kernel is rebuilt with the fbpaint boot-arg, which paints
the whole panel memory red when the display driver starts -- no frame needed, so the screen itself
answers whether the panel, its backlight and the controller's scan-out survived the kernel.
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p33"
P32 = "/root/star26/p32"
SRC = BASE + "/src"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p33-payload.bin"
OUT_BOOT = BASE + "/p33-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
NEW_KERNEL = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
CMDLINE = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 "
           "cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
           "loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1 "
           "autounlock=1 fbpaint=1")

for d in (BASE, SRC, PARTS):
    os.makedirs(d, exist_ok=True)

with open(os.path.join(SRC, "cmdline"), "w") as f:
    f.write(CMDLINE)
print("cmdline (%d bytes): %s" % (len(CMDLINE), CMDLINE))
assert len(CMDLINE) < 1023

for name in ("loader.efi", "ramdisk", "rdimage", "memsize", "identity"):
    shutil.copy(os.path.join(P32, "parts", name), os.path.join(PARTS, name))
shutil.copy(os.path.join(SRC, "cmdline"), os.path.join(PARTS, "cmdline"))
shutil.copy(NEW_KERNEL, os.path.join(PARTS, "kernel"))
for name in ("kernel", "ramdisk", "loader.efi", "rdimage"):
    print("  %-10s %d bytes" % (name, os.path.getsize(os.path.join(PARTS, name))))

def read_str(name):
    with open(os.path.join(PARTS, name), "rb") as f:
        return f.read().split(b"\0", 1)[0].decode("ascii")

print("=== mkpayload ===")
r = subprocess.run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
                    "loader.efi=" + os.path.join(PARTS, "loader.efi"),
                    "kernel=" + os.path.join(PARTS, "kernel"),
                    "ramdisk=" + os.path.join(PARTS, "ramdisk"),
                    "rdimage=" + os.path.join(PARTS, "rdimage"),
                    "--cmdline", read_str("cmdline"),
                    "--memsize", read_str("memsize"),
                    "--identity", read_str("identity")], capture_output=True, text=True)
print(r.stdout.strip()); print(r.stderr.strip())
if r.returncode != 0:
    sys.exit(r.returncode)

print("=== reseal ===")
r = subprocess.run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD],
                   capture_output=True, text=True)
print(r.stdout.strip()); print(r.stderr.strip())
if os.path.exists(OUT_BOOT):
    print("OUT_BOOT:", os.path.getsize(OUT_BOOT))
sys.exit(r.returncode)
