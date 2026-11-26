#!/usr/bin/env python3
"""P32 = P30 + rc.jobs additions: framewatch and four delayed unlock notifications.

The kernel, loader.efi, rdimage, memsize, identity and cmdline are exactly P30's (the stable
baseline with autounlock=1, without P31's rec_* arguments). The only change is inside the
helper ramdisk's /annibale/etc/rc.jobs: anntouch posts com.annibale.unlock at 150/200/260/320
seconds, when the lock screen has actually been drawn (first_frame was 100-221 s in P29/P30).
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p32"
P30 = "/root/star26/p30"
REL = "/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root"
SRC = BASE + "/src"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p32-payload.bin"
OUT_BOOT = BASE + "/p32-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
NEW_KERNEL = "/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
CMDLINE = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 "
           "cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
           "loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1 "
           "autounlock=1")

RC_JOBS = """# star: nothing can touch the screen yet, so the lock screen is unlocked from underneath.
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/framewatch &
/annibale/bin/anntouch wait 150 notify com.annibale.unlock &
/annibale/bin/anntouch wait 200 notify com.annibale.unlock &
/annibale/bin/anntouch wait 260 notify com.annibale.unlock &
/annibale/bin/anntouch wait 320 notify com.annibale.unlock &
"""

for d in (BASE, SRC, PARTS):
    os.makedirs(d, exist_ok=True)

rc = os.path.join(REL, "etc/rc.jobs")
backup = rc + ".star-orig"
if not os.path.exists(backup):
    shutil.copy(rc, backup)
    print("backed up", rc, "->", backup)
with open(rc, "w") as f:
    f.write(RC_JOBS)
print("rc.jobs written:")
print(RC_JOBS)

print("=== rebuilding root.apfs ===")
r = subprocess.run([sys.executable, "/mnt/d/桌面/star26-deps/scripts/build-star26-root.py",
                    "--fw", "/root/star26/p2/fw", "--ipsw", "/root/star26/ipsw",
                    "--work", BASE + "/work/rootbuild", "--output", BASE + "/root.apfs"],
                   capture_output=True, text=True)
tail = r.stdout[-1500:]
print(tail)
print(r.stderr[-1500:])
if r.returncode != 0:
    sys.exit("root.apfs build failed")

with open(os.path.join(SRC, "cmdline"), "w") as f:
    f.write(CMDLINE)
print("cmdline (%d bytes): %s" % (len(CMDLINE), CMDLINE))

for name in ("loader.efi", "rdimage", "memsize", "identity"):
    shutil.copy(os.path.join(P30, "src", name), os.path.join(PARTS, name))
shutil.copy(BASE + "/root.apfs", os.path.join(PARTS, "ramdisk"))
shutil.copy(os.path.join(SRC, "cmdline"), os.path.join(PARTS, "cmdline"))
shutil.copy(NEW_KERNEL, os.path.join(PARTS, "kernel"))
print("ramdisk:", os.path.getsize(os.path.join(PARTS, "ramdisk")), "bytes")
print("kernel :", os.path.getsize(os.path.join(PARTS, "kernel")), "bytes")

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
