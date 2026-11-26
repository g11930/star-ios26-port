#!/usr/bin/env python3
"""make-boot.py <tag> <prev-tag> <checkpoint> [key=value ...]

Generic single-variable packager: copy every part from /root/star26/<prev>/parts
byte for byte, replace ONLY the kernel with the current BUILD product, then
mkpayload + reseal into /root/star26/<tag>/<tag>-boot.img and C:/ios26.

Extra key=value arguments rewrite that token in the inherited cmdline
(replace in place if the key exists, append otherwise; pass an EMPTY value to
delete the key), which keeps the
"one variable per boot" rule without a rebuild.
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys

TAG = sys.argv[1]
PREV = sys.argv[2]
CKPT = sys.argv[3] if len(sys.argv) > 3 else "114"
OVERRIDES = {}
for a in sys.argv[4:]:
    if "=" not in a:
        raise SystemExit("cmdline override must be key=value, got %r" % a)
    k, v = a.split("=", 1)
    OVERRIDES[k] = v

BASE = "/root/star26/" + TAG
PARTS = BASE + "/parts"
PREV_PARTS = "/root/star26/" + PREV + "/parts"
NEW_KERNEL = "/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837"
MKPAYLOAD = "/root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py"
RESEAL = "/root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py"
REF_BOOT = "/root/star26/p2/p2-boot.img"
OUT_PAYLOAD = BASE + "/" + TAG + "-payload.bin"
OUT_BOOT = BASE + "/" + TAG + "-boot.img"
ASCII_OUT = "/mnt/c/ios26/" + TAG + "-boot.img"

SAME = ("loader.efi", "ramdisk", "rdimage", "memsize", "identity", "cmdline")


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
    print("=== 1. %s parts, byte for byte ===" % PREV)
    for name in SAME:
        a, b = os.path.join(PREV_PARTS, name), os.path.join(PARTS, name)
        shutil.copyfile(a, b)
        assert sha(a) == sha(b)
        print("  %-10s %10d  %s" % (name, os.path.getsize(b), sha(b)[:16]))

    print("=== 2. current kernel ===")
    kdst = os.path.join(PARTS, "kernel")
    shutil.copyfile(NEW_KERNEL, kdst)
    blob = open(kdst, "rb").read()
    magic, cputype, cpusub, ft, ncmds, sz, flags, res = struct.unpack_from("<IiiIIIII", blob, 0)
    sub = cpusub & 0xFFFFFFFF
    print("  size %d  cputype %#x  cpusubtype %#x" % (len(blob), cputype & 0xFFFFFFFF, sub))
    assert (sub & 0x00FFFFFF) == 0, "kernel is NOT plain arm64"
    for tag in (b"STAR0: bsdinit_task alive", b"STARL ", b"LIP_ENTER", b"LM_PARSE"):
        assert tag in blob, "tag %r missing" % tag
    print("  %s" % sha(kdst)[:16])

    cmdline = open(os.path.join(PARTS, "cmdline"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    if OVERRIDES:
        toks = cmdline.split()
        seen = set()
        drop = set()
        for i, t in enumerate(toks):
            k = t.split("=", 1)[0]
            if k in OVERRIDES:
                if OVERRIDES[k] == "":
                    drop.add(i)          # key= with an empty value removes the token
                else:
                    toks[i] = k + "=" + OVERRIDES[k]
                seen.add(k)
        for k, v in OVERRIDES.items():
            if k not in seen and v != "":
                toks.append(k + "=" + v)
        toks = [t for j, t in enumerate(toks) if j not in drop]
        cmdline = " ".join(toks)
        with open(os.path.join(PARTS, "cmdline"), "wb") as fh:
            fh.write(cmdline.encode("ascii") + b"\0")
    memsize = open(os.path.join(PARTS, "memsize"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    identity = open(os.path.join(PARTS, "identity"), "rb").read().split(b"\0", 1)[0].decode("ascii")
    print("=== 3. cmdline (%d) %s" % (len(cmdline), cmdline))
    assert len(cmdline) < 1024

    print("=== 4. mkpayload --checkpoint %s ===" % CKPT)
    run([sys.executable, MKPAYLOAD, "-o", OUT_PAYLOAD,
         "loader.efi=" + os.path.join(PARTS, "loader.efi"),
         "kernel=" + kdst,
         "ramdisk=" + os.path.join(PARTS, "ramdisk"),
         "rdimage=" + os.path.join(PARTS, "rdimage"),
         "--cmdline", cmdline, "--memsize", memsize, "--identity", identity,
         "--checkpoint", CKPT])

    print("=== 5. reseal ===")
    run([sys.executable, RESEAL, "-o", OUT_BOOT, REF_BOOT, OUT_PAYLOAD])
    print("  %s %d  sha256 %s" % (OUT_BOOT, os.path.getsize(OUT_BOOT), sha(OUT_BOOT)))
    shutil.copyfile(OUT_BOOT, ASCII_OUT)
    print("  ASCII copy: %s" % ASCII_OUT)
    print("DONE (no device was touched)")


if __name__ == "__main__":
    main()
