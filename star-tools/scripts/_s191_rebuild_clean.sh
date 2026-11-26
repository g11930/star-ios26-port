#!/bin/bash
# Rebuild s191 from s175 parts, replacing ONLY ramdisk with the new icon-dylib ramdisk.
set -e
B=/root/star26/baseline/s175parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] extract all 7 parts from s175 ==="
for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  rm -f "/tmp/$name.bin"
  python3 "$X" /mnt/c/ios26/s175-boot.img "$name" >/dev/null 2>&1 || true
  [ -f "/tmp/$name.bin" ] && mv -f "/tmp/$name.bin" "$B/$name"
done
ls -la "$B"

echo "=== [2] verify extracted kernel md5 matches s175 (1192343a) ==="
md5sum "$B/kernel" "$B/ramdisk"

echo "=== [3] replace ramdisk with new one (icon dylib) ==="
NEW_RD=/root/star26/s111/parts/ramdisk
md5sum "$NEW_RD"
cp -f "$NEW_RD" "$B/ramdisk"
echo "ramdisk replaced"

echo "=== [4] rebuild payload + boot.img N=191 ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s191-payload.bin" \
  loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(cat "$B/cmdline" | tr -d '\0')" \
  --memsize "$(cat "$B/memsize" | tr -d '\0')" \
  --identity "$(cat "$B/identity" | tr -d '\0')" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s191-boot.img /root/star26/p2/p2-boot.img "$B/s191-payload.bin" 2>&1 | tail -1

echo "=== [5] verify component md5 of final ==="
python3 "$X" /mnt/c/ios26/s191-boot.img 2>&1 | grep -E "kernel|ramdisk|cmdline" | head -5
sha256sum /mnt/c/ios26/s191-boot.img
