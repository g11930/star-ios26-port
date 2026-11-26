#!/usr/bin/env python3
"""P38 = P37 + RWA_SOFTWARE for triangle_app, so the software rasterizer is what gets tested.

P37 ran triangle_app and it answered backend=none: "the kernel's msm device opened but freedreno
made no screen for it". The reason is upstream of the driver -- the kernel adds RWA_SOFTWARE=1 to
a process only when etc/inject.conf names it, and inject.conf names no triangle_app. So P37 tested
the GPU path that cannot work on this phone, not the software path that is supposed to.

This build adds triangle_app to the video-toolbox line, which is where this port already keeps
test programs (video_decode_test, video_player_test): the library hooks VideoToolbox, which a
triangle never calls, so what changes for that process is the environment and nothing else.

What the answer will mean, in the port's own words:
  softpipe named          the software device opens -> draws can be looked at
  blue and orange pixels  the software rasterizer draws correctly -> the black frames are the
                          compositor's state, not the rasterizer
  black again             the software rasterizer itself produces nothing -> that is the bug
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p38"
P37 = "/root/star26/p37"
REL = "/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root"
SRC = BASE + "/src"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p38-payload.bin"
OUT_BOOT = BASE + "/p38-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"

VT_LINE = ("/annibale/lib/libannibale-vt.dylib videocodecd mediaserverd com.apple.WebKit.GPU "
           "video_decode_test video_player_test")

for d in (BASE, SRC, PARTS):
    os.makedirs(d, exist_ok=True)

# 1. inject.conf: triangle_app on the VideoToolbox line.
conf = os.path.join(REL, "etc/inject.conf")
backup = conf + ".p37"
if not os.path.exists(backup):
    shutil.copy(conf, backup)
    print("backed up inject.conf ->", backup)
text = open(conf).read()
if "triangle_app" in text:
    print("inject.conf already names triangle_app")
else:
    assert VT_LINE in text, "vt line not found in inject.conf:\n" + text
    text = text.replace(VT_LINE, VT_LINE + " triangle_app", 1)
    open(conf, "w").write(text)
    print("inject.conf: triangle_app added to the video-toolbox line")

# 2. root.apfs with the same job list as P37 (it did run triangle_app).
print("=== rebuilding root.apfs ===")
r = subprocess.run([sys.executable, "/mnt/d/桌面/star26-deps/scripts/build-star26-root.py",
                    "--fw", "/root/star26/p2/fw", "--ipsw", "/root/star26/ipsw",
                    "--work", BASE + "/work/rootbuild", "--output", BASE + "/root.apfs"],
                   capture_output=True, text=True)
print(r.stdout[-1200:])
print(r.stderr[-600:])
if r.returncode != 0:
    sys.exit("root.apfs build failed")

for name in ("loader.efi", "rdimage", "memsize", "identity", "cmdline", "kernel"):
    shutil.copy(os.path.join(P37, "parts", name), os.path.join(PARTS, name))
shutil.copy(BASE + "/root.apfs", os.path.join(PARTS, "ramdisk"))
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
