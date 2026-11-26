#!/bin/bash
# s221 = rewritten PAC subsystem kernel + s217 ramdisk/K90 dylib + s208 components
# Single variable vs s217: the kernel's PAC subsystem + cmdline PAC gate args.
set -e
B=/root/star26/baseline/s221parts
S208=/root/star26/baseline/s208parts
S215=/root/star26/baseline/s215parts
S207=/root/star26/baseline/s207parts
KNEW=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s221-boot.img

mkdir -p "$B"

echo "=== [1] components from s208; ramdisk from s215; NEW kernel ==="
for name in loader.efi rdimage memsize identity; do cp -f "$S208/$name" "$B/$name"; done
cp -f "$S215/ramdisk" "$B/ramdisk"
cp -f "$KNEW" "$B/kernel"
echo -n "  kernel md5  "; md5sum "$B/kernel" | cut -d' ' -f1
echo -n "  ramdisk md5 "; md5sum "$B/ramdisk" | cut -d' ' -f1

echo "=== [2] kernel carries new PAC gate diagnostics ==="
for s in "pac: rewrite gate OPEN" "pac_patch_delay" "pac_patch_budget"; do
  if grep -a -q "$s" "$B/kernel"; then echo "  FOUND: $s"; else echo "  MISSING: $s"; exit 1; fi
done

echo "=== [3] cmdline: s207 base + NEW PAC gate args (no pac_patch=0) ==="
CL=$(tr -d '\0' < "$S207/cmdline")
CL="${CL} gpu_irq=0 pac_patch=2 pac_patch_delay=900 pac_patch_budget=256 pac_patch_burst=8"
echo "  length ${#CL} (limit 1024)"
if [ ${#CL} -gt 1024 ]; then echo "  TOO LONG"; exit 1; fi
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac
echo "  $CL" | tail -c 160

echo "=== [4] repack + reseal ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s221-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -2
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s221-payload.bin" 2>&1 | tail -2

echo "=== [5] verify image ==="
ls -l "$IMG"
md5sum "$IMG"
python3 "$X" "$IMG" 2>/dev/null | grep -E 'cmdline|kernel|ramdisk|payload' | head -8
echo "DONE"
