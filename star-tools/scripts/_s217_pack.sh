#!/bin/bash
# s217 = s216 内核(GPU 10 档) + s215 ramdisk(K90 dylib, 无软件图标补丁) + s208 其余组件与 cmdline
set -e
B=/root/star26/baseline/s217parts
S208=/root/star26/baseline/s208parts
S215=/root/star26/baseline/s215parts
S216=/root/star26/baseline/s216parts
S207=/root/star26/baseline/s207parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s217-boot.img

mkdir -p "$B"

echo "=== [1] components: loader/rdimage/memsize/identity from s208; kernel from s216; ramdisk from s215 ==="
for name in loader.efi rdimage memsize identity; do cp -f "$S208/$name" "$B/$name"; done
cp -f "$S216/kernel"  "$B/kernel"
cp -f "$S215/ramdisk" "$B/ramdisk"
echo "  kernel  md5 $(md5sum "$B/kernel"  | cut -d' ' -f1)  (expect aac28bcf = s216)"
echo "  ramdisk md5 $(md5sum "$B/ramdisk" | cut -d' ' -f1)  (expect same as s215)"

echo "=== [2] the ramdisk really carries the K90 dylib (151712 bytes), not star's (136240) ==="
export PYTHONPATH=/mnt/d/桌面/star26-deps/tools/apfs
rm -rf /tmp/s217rd && mkdir -p /tmp/s217rd
python3 /mnt/d/桌面/star26-deps/scripts/apfs-extract.py "$B/ramdisk" /tmp/s217rd >/dev/null 2>&1 || true
D=$(find /tmp/s217rd -name "libannibale-sb26.dylib" | head -1)
if [ -z "$D" ]; then echo "  dylib not found in ramdisk"; exit 1; fi
ls -la "$D"
echo -n "  md5: "; md5sum "$D" | cut -d' ' -f1
echo -n "  size check (K90 = 151712): "; stat -c%s "$D"
echo -n "  software-icon patch marker absent: "
if grep -a -q "software_icons_installed" "$D"; then echo "STILL PRESENT (bad)"; exit 1; else echo "yes"; fi
echo -n "  K90 unlock marker present (waiting for the lock screen): "
if grep -a -q "waiting for the lock screen" "$D"; then echo "yes"; else echo "no"; fi

echo "=== [3] cmdline identical to s208 ==="
CL=$(tr -d '\0' < "$S207/cmdline"); CL="${CL} gpu_irq=0 pac_patch=0"
echo "  length ${#CL}"
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac

echo "=== [4] kernel still carries the 10-speed table ==="
python3 - "$B/kernel" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
need = [315000, 379000, 443000, 491000, 540000, 608000, 676000, 738000, 778000, 840000]
bad = [v for v in need if d.count(struct.pack("<I", v)) < 1]
print("  frequencies found: %d of %d %s" % (len(need) - len(bad), len(need), ("missing %s" % bad) if bad else ""))
sys.exit(1 if bad else 0)
PY

echo "=== [5] repack + reseal ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s217-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s217-payload.bin" 2>&1 | tail -1

echo "=== [6] payload-level single-variable check (s217 vs s208) ==="
for t in s208 s217; do
  echo "--- $t ---"
  python3 "$X" /mnt/c/ios26/$t-boot.img 2>/dev/null | grep -E '^\s+(loader|kernel|ramdisk|rdimage|cmdline|memsize|identity)' | head -8
done

echo "=== [7] which sections differ from s208 ==="
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
a = secs("/mnt/c/ios26/s208-boot.img"); b = secs("/mnt/c/ios26/s217-boot.img")
for k in a:
    if k in b and a[k] != b[k]:
        print("  DIFFERS:", k, a[k], "->", b[k])
same = [k for k in a if k in b and a[k] == b[k]]
print("  identical sections:", ", ".join(same))
PY

echo "=== [8] result ==="
sha256sum "$IMG"
ls -la "$IMG"
