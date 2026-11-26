#!/bin/bash
# s200 = s199 的 7 个组件原样 + 唯一变量 = cmdline 追加 " fb_diff=1"。
#
# 为什么只用 fb_diff=1（而不加 fb_rows=0）：
#   MiniFramebufferRows.inc:251 的 dirtyBand() 第一层判断是
#       if (!gRows || !fSingleLayer || fDiff || ...) { fRowHashRows = 0; ...; return true; }
#   fDiff 为真时直接短路返回 true（整帧重画）、完全跳过行哈希，所以 fb_rows=0 是冗余的。
#   主 cpp:776 的 `if (fThreads <= 1 || fDiff || ...)` 也会把绘制改成单线程。
#   于是 fb_diff=1 一个开关同时拿到 P1（每帧真实变化像素数）与 P2（强制整帧重画）。
#
# 闸门：除 cmdline 之外任何组件变化都算破单变量，直接退出。
set -e
B=/root/star26/baseline/s200parts
OLD=/root/star26/baseline/s199parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] copy the 7 components from s199 ==="
for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] guard: kernel must still be 6db658801dd1031ae7cfc1f8e524eff9 ==="
K=$(md5sum "$B/kernel" | cut -d' ' -f1)
[ "$K" = "6db658801dd1031ae7cfc1f8e524eff9" ] || { echo "KERNEL MISMATCH: $K"; exit 1; }
echo "kernel ok"

echo "=== [3] guard: ramdisk must still be 85c849db42762a065ae2ce4f68a9cad0 ==="
R=$(md5sum "$B/ramdisk" | cut -d' ' -f1)
[ "$R" = "85c849db42762a065ae2ce4f68a9cad0" ] || { echo "RAMDISK MISMATCH: $R"; exit 1; }
echo "ramdisk ok"

echo "=== [4] append fb_diff=1 to cmdline (idempotent) ==="
CL=$(tr -d '\0' < "$B/cmdline")
echo "before ($(printf '%s' "$CL" | wc -c) B): $CL"
case "$CL" in
  *fb_diff=*) echo "fb_diff already present, leaving as is" ;;
  *) CL="$CL fb_diff=1" ;;
esac
printf '%s' "$CL" > "$B/cmdline"
echo "after  ($(printf '%s' "$CL" | wc -c) B): $CL"
case "$CL" in
  *fb_diff=1*) echo "fb_diff=1 present" ;;
  *) echo "FB_DIFF MISSING"; exit 1 ;;
esac
case "$CL" in
  *touch_lat=1*) echo "touch_lat=1 still present" ;;
  *) echo "TOUCH_LAT LOST"; exit 1 ;;
esac

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s200-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s200-boot.img /root/star26/p2/p2-boot.img "$B/s200-payload.bin" 2>&1 | tail -1

echo "=== [6] single-variable check: cmdline only ==="
echo "--- s200 ---"
python3 "$X" /mnt/c/ios26/s200-boot.img 2>&1 | head -12
echo "--- s199 for comparison ---"
python3 "$X" /mnt/c/ios26/s199-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s200-boot.img
