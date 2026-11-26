#!/bin/bash
# s203 = s201 的 6 个非内核组件 + 新内核（pac_patch 类别掩码 + 放大诊断）
#        cmdline 末尾 pac_patch=2 —— 只改写 RETAA/RETAB -> ret，其余走慢路径。
# 目的：区分「改写动作本身有问题」还是「某一类改写语义有问题」。
set -e
B=/root/star26/baseline/s203parts
OLD=/root/star26/baseline/s201parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
mkdir -p "$B"

echo "=== [1] six non-kernel components from s201 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1); C=$(md5sum "$B/$name" | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all five identical to s201"

echo "=== [2] cmdline: s201 + pac_patch=2 ==="
CL=$(tr -d '\0' < "$OLD/cmdline")
case "$CL" in
  *pac_patch=*) CL=$(printf '%s' "$CL" | sed 's/pac_patch=[0-9]*/pac_patch=2/');;
  *) CL="$CL pac_patch=2";;
esac
printf '%s' "$CL" > "$B/cmdline"
echo "cmdline $(printf '%s' "$CL" | wc -c) B"
for a in touch_diag=0 touch_lat=1 fb_diff=1 pac_patch=2; do
  case "$CL" in *"$a"*) echo "  $a present";; *) echo "  $a MISSING"; exit 1;; esac
done

echo "=== [3] new kernel ==="
NK=$(md5sum "$NEWK" | cut -d' ' -f1); OK=$(md5sum "$OLD/kernel" | cut -d' ' -f1)
echo "new $NK / old $OK"
[ "$NK" != "$OK" ] || { echo "KERNEL UNCHANGED"; exit 1; }
cp -f "$NEWK" "$B/kernel"

echo "=== [4] mask symbol must be linked ==="
llvm-nm "$NU" 2>/dev/null | grep -E '_pac_patch_mask' || { echo "NO MASK SYMBOL"; exit 1; }

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s203-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s203-boot.img /root/star26/p2/p2-boot.img "$B/s203-payload.bin" 2>&1 | tail -1

echo "=== [6] components ==="
python3 "$X" /mnt/c/ios26/s203-boot.img 2>&1 | head -10
sha256sum /mnt/c/ios26/s203-boot.img
