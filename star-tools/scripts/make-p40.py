#!/usr/bin/env python3
"""P40 = P39 + the SoC-identity kernel (one variable: the kernel binary).

P39 removed fbpaint=1 from the cmdline. P40 keeps that cmdline, the P38 loader.efi,
rdimage and root.apfs byte-for-byte, and swaps in the freshly built 12377 RELEASE
kernel from build-k90-tree.sh, which now:
  * reads MIDR_EL1 and names the real silicon (SM8350 "star" / Snapdragon 888 /
    Xiaomi 11 Ultra / Adreno 660) in the boot log,
  * states that the A8XX/Adreno 830 bring-up is disabled on this SoC,
  * no longer claims in any printed message that this phone is an SM8750.

No register value and no driver flow was changed. If P39 boots to END OF LOG and
P40 panics, the kernel patch is the only difference.
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p40"
P39 = "/root/star26/p39"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p40-payload.bin"
OUT_BOOT = BASE + "/p40-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
NEW_KERNEL = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"

os.makedirs(PARTS, exist_ok=True)
for name in ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline"):
    shutil.copy(os.path.join(P39, "parts", name), os.path.join(PARTS, name))
shutil.copy(NEW_KERNEL, os.path.join(PARTS, "kernel"))

def read_str(name):
    with open(os.path.join(PARTS, name), "rb") as f:
        return f.read().split(b"\0", 1)[0].decode("ascii")

cmdline = read_str("cmdline")
print("cmdline (%d bytes): %s" % (len(cmdline), cmdline))
assert "fbpaint" not in cmdline, "P40 must keep P39's cmdline without fbpaint"
assert len(cmdline) < 1023

print("=== parts ===")
for name in ("kernel", "ramdisk", "loader.efi", "rdimage"):
    print("  %-10s %d bytes" % (name, os.path.getsize(os.path.join(PARTS, name))))

print("=== mkpayload ===")
r = subprocess.run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
                    "loader.efi=" + os.path.join(PARTS, "loader.efi"),
                    "kernel=" + os.path.join(PARTS, "kernel"),
                    "ramdisk=" + os.path.join(PARTS, "ramdisk"),
                    "rdimage=" + os.path.join(PARTS, "rdimage"),
                    "--cmdline", cmdline,
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
