#!/usr/bin/env python3
"""P39 = P38 with exactly one change: remove fbpaint=1 from the kernel arguments.

Why: P38's kernel log prints, on lines 106-109,
    MiniIOMobileFramebuffer: flip: gcc_disp_ahb_clk 00000000 -> 00000001
    MiniIOMobileFramebuffer: painted the panel memory 0xffff0000 ... at 0xea600000
    MiniIOMobileFramebuffer: display 1125x2436 on a panel of 1440x3200
and the loader's boot splash (apple, progress bar, KERNEL BOOT CONSOLE card) is then
gone from the screen, frozen at its last visible value: 40% ("Configuring DPU display
pipes"). P21 has zero occurrences of flip / gcc_disp_ahb_clk / painted / display, and its
splash stayed on screen all the way to 76%. P33 swapped in a freshly built kernel as well
as adding fbpaint=1, so those two causes are confounded.

This build changes ONLY the cmdline. Everything else - the P38 kernel, loader.efi,
rdimage, root.apfs (with the triangle job and the inject.conf fix) - is byte-identical.
It separates "the red fill" from "the display takeover": if the red is gone but the
splash still freezes at 40%, the new kernel's DPU takeover is the cause; if the splash
runs to 76% again, the red fill was covering it.
"""
import os, shutil, subprocess, sys

BASE = "/root/star26/p39"
P38 = "/root/star26/p38"
PARTS = BASE + "/parts"
OUT_PAYLOAD = BASE + "/p39-payload.bin"
OUT_BOOT = BASE + "/p39-boot.img"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"

os.makedirs(PARTS, exist_ok=True)
for name in ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "kernel", "cmdline"):
    shutil.copy(os.path.join(P38, "parts", name), os.path.join(PARTS, name))

p = os.path.join(PARTS, "cmdline")
b = open(p, "rb").read()
assert b" fbpaint=1" in b, "no fbpaint=1 in P38 cmdline: %r" % b
b2 = b.replace(b" fbpaint=1", b"", 1)
assert b"fbpaint" not in b2
assert len(b2) < 1023
open(p, "wb").write(b2)
print("cmdline %d -> %d bytes" % (len(b), len(b2)))
print(b2.decode("ascii"))

def read_str(name):
    with open(os.path.join(PARTS, name), "rb") as f:
        return f.read().split(b"\0", 1)[0].decode("ascii")

print("=== parts ===")
for name in ("kernel", "ramdisk", "loader.efi", "rdimage"):
    print("  %-10s %d bytes" % (name, os.path.getsize(os.path.join(PARTS, name))))

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
