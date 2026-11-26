#!/bin/bash
# s202 = s201 原样，唯一变量 = cmdline 末尾追加 pac_patch=0（关掉页级改写，退回纯模拟）。
# 目的：判定 mount-phase-2 的 "boot task is not a platform binary" panic 是否由 PAC 页改写引起。
set -e
B=/root/star26/baseline/s202parts
OLD=/root/star26/baseline/s201parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
mkdir -p "$B"

echo "=== [1] copy s201 components unchanged ==="
for name in loader.efi kernel ramdisk rdimage memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done

echo "=== [2] guard: all six identical to s201 ==="
for name in loader.efi kernel ramdisk rdimage memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all six identical"

echo "=== [3] cmdline: s201 + pac_patch=0 ==="
CL=$(tr -d '\0' < "$OLD/cmdline")
case "$CL" in
  *pac_patch=*) echo "already has pac_patch";;
  *) CL="$CL pac_patch=0";;
esac
printf '%s' "$CL" > "$B/cmdline"
LEN=$(printf '%s' "$CL" | wc -c)
echo "cmdline now ${LEN} B (limit 1024)"
[ "$LEN" -lt 1000 ] || { echo "CMDLINE TOO LONG"; exit 1; }
for a in touch_diag=0 touch_lat=1 fb_diff=1 pac_patch=0; do
  case "$CL" in
    *"$a"*) echo "  $a present" ;;
    *) echo "  $a MISSING"; exit 1 ;;
  esac
done

echo "=== [4] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s202-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s202-boot.img /root/star26/p2/p2-boot.img "$B/s202-payload.bin" 2>&1 | tail -1

echo "=== [5] single-variable check: only cmdline differs from s201 ==="
echo "--- s202 ---"
python3 "$X" /mnt/c/ios26/s202-boot.img 2>&1 | head -12
echo "--- s201 for comparison ---"
python3 "$X" /mnt/c/ios26/s201-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s202-boot.img
