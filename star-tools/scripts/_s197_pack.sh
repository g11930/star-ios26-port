#!/bin/bash
# s197 = s196 的组件原样 + cmdline 追加 touch_diag=0。单变量 = 只改 cmdline。
set -e
B=/root/star26/baseline/s197parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] extract s196 parts (not s192: keep s196 kernel) ==="
for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  rm -f "/tmp/$name.bin"
  python3 "$X" /mnt/c/ios26/s196-boot.img "$name" >/dev/null 2>&1 || true
  [ -f "/tmp/$name.bin" ] && mv -f "/tmp/$name.bin" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] expect s196 kernel 81c54bbb545afdc49ae709e9b4e3d82f ==="
K=$(md5sum "$B/kernel" | cut -d' ' -f1)
if [ "$K" != "81c54bbb545afdc49ae709e9b4e3d82f" ]; then echo "KERNEL MISMATCH: $K"; exit 1; fi
echo "kernel ok"

echo "=== [3] patch cmdline: append touch_diag=0 ==="
CL=$(tr -d '\0' < "$B/cmdline")
case "$CL" in
  *touch_diag=*) echo "already has touch_diag: $CL" ;;
  *) CL="$CL touch_diag=0"; echo "new: $CL" ;;
esac
printf '%s\n' "$CL" > "$B/cmdline"
echo "cmdline bytes: $(wc -c < "$B/cmdline") (limit 1024)"

echo "=== [4] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s197-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(tr -d '\0' < "$B/cmdline")" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s197-boot.img /root/star26/p2/p2-boot.img "$B/s197-payload.bin" 2>&1 | tail -1

echo "=== [5] single-variable check: only cmdline may differ from s196 ==="
python3 "$X" /mnt/c/ios26/s197-boot.img 2>&1 | head -10
echo "--- s196 for comparison ---"
python3 "$X" /mnt/c/ios26/s196-boot.img 2>&1 | head -10
sha256sum /mnt/c/ios26/s197-boot.img
