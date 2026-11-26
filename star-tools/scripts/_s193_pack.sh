#!/bin/bash
# s193 = s192 parts, kernel replaced with STM-touch-enabled build. Single variable = kernel.
set -e
B=/root/star26/baseline/s193parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] extract s192 parts ==="
for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  rm -f "/tmp/$name.bin"
  python3 "$X" /mnt/c/ios26/s192-boot.img "$name" >/dev/null 2>&1 || true
  [ -f "/tmp/$name.bin" ] && mv -f "/tmp/$name.bin" "$B/$name"
done
md5sum "$B/kernel" "$B/ramdisk"

echo "=== [2] replace kernel with new STM build ==="
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
cp -f "$K" "$B/kernel"
md5sum "$B/kernel"
ls -la "$B/kernel"

echo "=== [3] verify STM strings in kernel ==="
strings "$B/kernel" | grep -E "stm: sense on|stm: chip id|GOODIX_INIT_ENTERED|stm: system-info" | head -5 || echo "NO STM STRINGS"

echo "=== [4] rebuild payload + boot.img ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s193-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(cat "$B/cmdline" | tr -d '\0')" --memsize "$(cat "$B/memsize" | tr -d '\0')" \
  --identity "$(cat "$B/identity" | tr -d '\0')" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s193-boot.img /root/star26/p2/p2-boot.img "$B/s193-payload.bin" 2>&1 | tail -1

echo "=== [5] verify single variable ==="
python3 "$X" /mnt/c/ios26/s193-boot.img 2>&1 | grep -E "kernel|ramdisk|cmdline" | head -3
sha256sum /mnt/c/ios26/s193-boot.img
