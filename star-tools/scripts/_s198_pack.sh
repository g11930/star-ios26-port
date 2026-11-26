#!/bin/bash
# s198 = s197 的组件原样 + cmdline 追加 touch_lat=1。单变量 = 只改 cmdline，内核二进制不动。
# 目的：打开 IOMobileFramebuffer 的逐 swap 打点（tl: s / tl: v / tl: l），
#       把"屏幕冻结"的剩余分支一次区分开：
#         tl: s  = 一次 swap 被用户态交给内核（谁、pid、何时）
#         tl: v  = presenter 线程把它画进面板内存（ready/shown/done 微秒）
#         tl: l  = 面板被观察到翻页（latch，帧号）
set -e
B=/root/star26/baseline/s198parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] extract s197 parts ==="
for name in loader.efi kernel ramdisk rdimage cmdline memsize identity; do
  rm -f "/tmp/$name.bin"
  python3 "$X" /mnt/c/ios26/s197-boot.img "$name" >/dev/null 2>&1 || true
  [ -f "/tmp/$name.bin" ] && mv -f "/tmp/$name.bin" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] guard: kernel must still be 81c54bbb545afdc49ae709e9b4e3d82f ==="
K=$(md5sum "$B/kernel" | cut -d' ' -f1)
if [ "$K" != "81c54bbb545afdc49ae709e9b4e3d82f" ]; then echo "KERNEL MISMATCH: $K"; exit 1; fi
echo "kernel ok"

echo "=== [3] guard: ramdisk must still be 85c849db42762a065ae2ce4f68a9cad0 ==="
R=$(md5sum "$B/ramdisk" | cut -d' ' -f1)
if [ "$R" != "85c849db42762a065ae2ce4f68a9cad0" ]; then echo "RAMDISK MISMATCH: $R"; exit 1; fi
echo "ramdisk ok"

echo "=== [4] patch cmdline: append touch_lat=1 ==="
CL=$(tr -d '\0' < "$B/cmdline")
case "$CL" in
  *touch_lat=*) echo "already has touch_lat: $CL" ;;
  *) CL="$CL touch_lat=1"; echo "new: $CL" ;;
esac
printf '%s\n' "$CL" > "$B/cmdline"
echo "cmdline bytes: $(wc -c < "$B/cmdline") (limit 1024)"

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s198-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(tr -d '\0' < "$B/cmdline")" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s198-boot.img /root/star26/p2/p2-boot.img "$B/s198-payload.bin" 2>&1 | tail -1

echo "=== [6] single-variable check: only cmdline may differ from s197 ==="
python3 "$X" /mnt/c/ios26/s198-boot.img 2>&1 | head -10
echo "--- s197 for comparison ---"
python3 "$X" /mnt/c/ios26/s197-boot.img 2>&1 | head -10
sha256sum /mnt/c/ios26/s198-boot.img
