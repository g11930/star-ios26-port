#!/usr/bin/env python3
"""P36 = P35 + the port's own triangle, drawn on this phone.

P35 answered the question it was built for and the answer was flat: the picture the compositor
hands the panel is black -- all 3969 samples of it, surface and panel alike -- while the panel,
its backlight and the scan-out are demonstrably alive (P33 painted it red). So the remaining
question is where the black starts, and the port already carries the instrument for it:

  /annibale/bin/triangle_app --layer   a bare CAMetalLayer of the panel's size, one frame,
                                       presented through the layer's CAImageQueue
  annibaletriangle://                  the same triangle inside an ordinary application,
                                       launched by SpringBoard through its URL scheme

Both draw a triangle (255,128,0) on a (0,0,255) clear, so the panel says which of the three
things happened: blue-and-orange means the whole chain works and the black is iOS's own doing;
blue alone means a frame reached the screen but the draw covered nothing; black means nothing
was presented at all.

The job list is rc.jobs.triangle's, minus the swipe (this phone has no touch; autounlock=1 has
already removed the lock screen) and with the waits stretched to this build's timing.
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p36"
P35 = "/root/star26/p35"
REL = "/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root"
SRC = BASE + "/src"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p36-payload.bin"
OUT_BOOT = BASE + "/p36-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"

CMDLINE = ("debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 "
           "cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 "
           "loader_return_after=420 adreno8=2 adreno8_only=2 rwa_software=1 "
           "autounlock=1 fbpaint=1")

RC_JOBS = """# star: the port's own triangle, so the panel says whether Metal draws here at all.
# init runs these lines itself: one program per line, arguments split on blanks.
/annibale/bin/metal_props on
/annibale/bin/anntouch wait 120
/annibale/bin/battery_test open annibaletriangle://
/annibale/bin/anntouch wait 40
/annibale/bin/triangle_app --layer
/annibale/bin/anntouch wait 200
"""

for d in (BASE, SRC, PARTS):
    os.makedirs(d, exist_ok=True)

rc = os.path.join(REL, "etc/rc.jobs")
backup = rc + ".p35"
if not os.path.exists(backup):
    shutil.copy(rc, backup)
    print("backed up rc.jobs ->", backup)
with open(rc, "w") as f:
    f.write(RC_JOBS)
print("rc.jobs now:\n" + RC_JOBS)

print("=== rebuilding root.apfs ===")
r = subprocess.run([sys.executable, "/mnt/d/桌面/star26-deps/scripts/build-star26-root.py",
                    "--fw", "/root/star26/p2/fw", "--ipsw", "/root/star26/ipsw",
                    "--work", BASE + "/work/rootbuild", "--output", BASE + "/root.apfs"],
                   capture_output=True, text=True)
print(r.stdout[-1500:])
print(r.stderr[-800:])
if r.returncode != 0:
    sys.exit("root.apfs build failed")

with open(os.path.join(SRC, "cmdline"), "w") as f:
    f.write(CMDLINE)
print("cmdline (%d bytes): %s" % (len(CMDLINE), CMDLINE))
assert len(CMDLINE) < 1023

for name in ("loader.efi", "rdimage", "memsize", "identity"):
    shutil.copy(os.path.join(P35, "parts", name), os.path.join(PARTS, name))
shutil.copy(BASE + "/root.apfs", os.path.join(PARTS, "ramdisk"))
shutil.copy(os.path.join(SRC, "cmdline"), os.path.join(PARTS, "cmdline"))
shutil.copy(os.path.join(P35, "parts", "kernel"), os.path.join(PARTS, "kernel"))
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
