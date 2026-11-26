#!/bin/bash
# s216 = s208 + 新内核(GPU 档位表换成 star 真机 10 档, 默认 840MHz)。单变量：只换内核。
set -e
B=/root/star26/baseline/s216parts
S208=/root/star26/baseline/s208parts
S207=/root/star26/baseline/s207parts
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=$NEWK.unstripped.noctf
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s216-boot.img

mkdir -p "$B"

echo "=== [1] 6 unchanged components from s208 + the new kernel ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  cp -f "$S208/$name" "$B/$name"
done
cp -f "$NEWK" "$B/kernel"
echo "  kernel md5: $(md5sum "$B/kernel" | cut -d' ' -f1)  (s208 kernel: $(md5sum "$S208/kernel" | cut -d' ' -f1))"

echo "=== [2] guard: the 5 other components must be byte-identical to s208 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$S208/$name" | cut -d' ' -f1); C=$(md5sum "$B/$name" | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "  ok: loader/ramdisk/rdimage/memsize/identity == s208"

echo "=== [3] cmdline: same as s208 (s207 cmdline + gpu_irq=0 pac_patch=0) ==="
CL=$(tr -d '\0' < "$S207/cmdline")
CL="${CL} gpu_irq=0 pac_patch=0"
echo "  length ${#CL} (limit 1024)"
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac
case "$CL" in *"pac_patch=0"*) :;; *) echo "  pac_patch=0 MISSING"; exit 1;; esac
case "$CL" in *"gpu_irq=0"*) :;; *) echo "  gpu_irq=0 MISSING"; exit 1;; esac
echo "  ok: no fb_diff, pac_patch=0 and gpu_irq=0 present"

echo "=== [4] the new kernel must carry the 10-speed table ==="
python3 - "$B/kernel" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
need = [315000, 379000, 443000, 491000, 540000, 608000, 676000, 738000, 778000, 840000]
bad = [v for v in need if d.count(struct.pack("<I", v)) < 1]
print("  frequencies found:", len(need) - len(bad), "of", len(need), ("missing: %s" % bad) if bad else "")
print("  new vote log present:", d.count(b"speeds, %u..%u MHz; votes") > 0)
if bad:
    sys.exit(1)
PY

echo "=== [5] repack payload + reseal into the boot image ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s216-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s216-payload.bin" 2>&1 | tail -1

echo "=== [6] single-variable check at payload level (s216 vs s208) ==="
echo "--- s208 ---"
python3 "$X" /mnt/c/ios26/s208-boot.img 2>&1 | grep -E '^\s+(loader|kernel|ramdisk|rdimage|cmdline|memsize|identity)|^cmdline' | head -10
echo "--- s216 ---"
python3 "$X" "$IMG" 2>&1 | grep -E '^\s+(loader|kernel|ramdisk|rdimage|cmdline|memsize|identity)|^cmdline' | head -10

echo "=== [7] cmdline of both images must be identical ==="
A=$(python3 "$X" /mnt/c/ios26/s208-boot.img 2>/dev/null | grep -i '^cmdline' | head -1)
C=$(python3 "$X" "$IMG" 2>/dev/null | grep -i '^cmdline' | head -1)
[ "$A" = "$C" ] && echo "  identical" || { echo "  CMDLINE DIFFERS"; echo "  s208: $A"; echo "  s216: $C"; exit 1; }

echo "=== [8] result ==="
sha256sum "$IMG"
ls -la "$IMG"
