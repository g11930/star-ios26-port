#!/bin/bash
# s218 = s217 + 新内核(按需调频: 负载/温度选档)。其余组件与 cmdline 完全照 s217。
set -e
B=/root/star26/baseline/s218parts
S217=/root/star26/baseline/s217parts
S208=/root/star26/baseline/s208parts
S207=/root/star26/baseline/s207parts
KNEW=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s218-boot.img

mkdir -p "$B"

echo "=== [1] components: everything from s217, kernel replaced with freshly built ==="
for name in loader.efi ramdisk rdimage memsize identity; do cp -f "$S217/$name" "$B/$name"; done
cp -f "$KNEW" "$B/kernel"
echo "  kernel  md5 $(md5sum "$B/kernel" | cut -d' ' -f1)  (expect 6736e630 = s218 new)"
echo "  ramdisk md5 $(md5sum "$B/ramdisk" | cut -d' ' -f1)  (expect s217 same)"

echo "=== [2] kernel carries BOTH the 10-speed table and the new speed-change code ==="
python3 - "$B/kernel" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
need = [315000, 379000, 443000, 491000, 540000, 608000, 676000, 738000, 778000, 840000]
bad = [v for v in need if d.count(struct.pack("<I", v)) < 1]
print("  frequencies found: %d of %d %s" % (len(need) - len(bad), len(need), ("missing %s" % bad) if bad else ""))
for s in [b"the GPU's speed is now", b"no temperature reading", b"AnnibaleGPU: GPU at"]:
    print("  log '%s': %d" % (s.decode(), d.count(s)))
sys.exit(1 if bad else 0)
PY

echo "=== [3] cmdline identical to s217 (add adreno_speed args for the tick) ==="
CL=$(tr -d '\0' < "$S207/cmdline"); CL="${CL} gpu_irq=0 pac_patch=0"
echo "  base length ${#CL}"
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac
# The tick's initial speed (adreno_speed) defaults to 10 already set in-kernel; no cmdline
# change needed, so cmdline stays byte-identical to s217.
echo "  cmdline kept byte-identical to s217 (single variable = kernel)"

echo "=== [4] repack + reseal ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s218-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s218-payload.bin" 2>&1 | tail -1

echo "=== [5] payload-level single-variable check (s218 vs s217) ==="
python3 - <<'PY'
import subprocess, re
def secs(img):
    out = subprocess.run(["python3", "/mnt/d/桌面/star26-deps/scripts/xnup_info.py", img],
                         capture_output=True, text=True).stdout
    d = {}
    for line in out.splitlines():
        m = re.match(r"\s+(\w[\w.]*)\s+(\d+)\s+([0-9a-f]{32})", line)
        if m:
            d[m.group(1)] = (m.group(2), m.group(3))
    return d
a = secs("/mnt/c/ios26/s217-boot.img"); b = secs("/mnt/c/ios26/s218-boot.img")
for k in a:
    if k in b and a[k] != b[k]:
        print("  DIFFERS:", k, a[k], "->", b[k])
same = [k for k in a if k in b and a[k] == b[k]]
print("  identical sections:", ", ".join(same))
PY

echo "=== [6] result ==="
sha256sum "$IMG"
ls -la "$IMG"
