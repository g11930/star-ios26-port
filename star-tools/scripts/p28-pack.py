#!/usr/bin/env python3
"""Pack P28: P27's parts, plus the kernel with the P28FAULT / P28EXIT probes.

Only two things differ from P27:
  * kernel  - rebuilt from the same tree with the two probes (md5 checked by the caller);
  * cmdline - loader_return_after 600 -> 420.  The crash loop starts 25 s after launchd
              and repeats with launchd's backoff, so 420 s still holds ten cycles and
              saves three minutes per iteration.
"""
import os, shutil, subprocess, sys

SRC_PARTS = "/root/star26/p27/src"
DST_PARTS = "/root/star26/p28/parts"
NEW_KERNEL = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
OUT_PAYLOAD = "/root/star26/p28/p28-payload.bin"
OUT_BOOT = "/root/star26/p28/p28-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
CMDLINE = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 "
           "bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
           "loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1")

os.makedirs(DST_PARTS, exist_ok=True)
for name in ("loader.efi", "ramdisk", "rdimage", "memsize", "identity"):
    shutil.copy(os.path.join(SRC_PARTS, name), os.path.join(DST_PARTS, name))
shutil.copy(NEW_KERNEL, os.path.join(DST_PARTS, "kernel"))
with open(os.path.join(DST_PARTS, "cmdline"), "w") as f:
    f.write(CMDLINE)


def read_str(name):
    with open(os.path.join(DST_PARTS, name), "rb") as f:
        return f.read().split(b"\0", 1)[0].decode("ascii")


memsize = read_str("memsize")
identity = read_str("identity")
print("cmdline :", CMDLINE)
print("memsize :", memsize)
print("identity:", identity)
print("kernel  :", os.path.getsize(os.path.join(DST_PARTS, "kernel")), "bytes")

cmd = [
    sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
    "loader.efi=" + os.path.join(DST_PARTS, "loader.efi"),
    "kernel=" + os.path.join(DST_PARTS, "kernel"),
    "ramdisk=" + os.path.join(DST_PARTS, "ramdisk"),
    "rdimage=" + os.path.join(DST_PARTS, "rdimage"),
    "--cmdline", CMDLINE,
    "--memsize", memsize,
    "--identity", identity,
]
print("Running mkpayload ...")
r = subprocess.run(cmd, capture_output=True, text=True)
print("STDOUT:", r.stdout.strip())
print("STDERR:", r.stderr.strip())
if r.returncode != 0:
    sys.exit(r.returncode)

print("Running reseal ...")
r2 = subprocess.run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD],
                    capture_output=True, text=True)
print("STDOUT:", r2.stdout.strip())
print("STDERR:", r2.stderr.strip())
if os.path.exists(OUT_BOOT):
    print("OUT_BOOT size:", os.path.getsize(OUT_BOOT))
sys.exit(r2.returncode)
