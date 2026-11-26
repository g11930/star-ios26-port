#!/bin/bash
# 把 s173（已知能进桌面）的部件抽出来做为基线，然后用它们重建一次，
# 验证重建结果与 s173-boot.img 逐字节一致 —— 一致才说明基线是完整可复现的。
set -e
B=/root/star26/baseline/s173
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  python3 "$X" /mnt/c/ios26/s173-boot.img "$name" 2>&1 | grep -E "dumped|$name " || true
  [ -f "/tmp/$name.bin" ] && mv -f "/tmp/$name.bin" "$B/$name"
done

echo
echo "=== 基线部件 ==="
ls -la "$B"
echo
echo "=== 与 s173 payload 内 md5 逐个核对 ==="
md5sum "$B"/*

echo
echo "=== 用基线部件重建 ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s173b-payload.bin" \
  loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(cat "$B/cmdline" | tr -d '\0')" \
  --memsize "$(cat "$B/memsize" | tr -d '\0')" \
  --identity "$(cat "$B/identity" | tr -d '\0')" 2>&1 | tail -2

python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$B/s173b-boot.img" /root/star26/p2/p2-boot.img "$B/s173b-payload.bin" 2>&1 | tail -2

echo
echo "=== 重建镜像 vs 原始 s173 ==="
md5sum "$B/s173b-boot.img" /mnt/c/ios26/s173-boot.img
cmp "$B/s173b-boot.img" /mnt/c/ios26/s173-boot.img && echo "IDENTICAL: 基线可逐字节复现" || echo "DIFFERS: 需检查（可能只是时间戳/id）"
