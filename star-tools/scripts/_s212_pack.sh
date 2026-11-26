#!/bin/bash
# s212 = s211 的非内核组件 + 新内核（mach_loader.c exec 初始页 CS_VALID 保护）
#        唯一变量：内核（s211 清 CS_VALID -> non-platform panic；s212 条件保留）。
#        cmdline 与 s211 完全相同（gpu_irq=0 pac_patch=2 + star_cs_keep_valid=1）。
set -e
B=/root/star26/baseline/s212parts
S211=/root/star26/baseline/s211parts
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
KMD5=0a3b5eda59bad5e7bce73640a11fe4ed

mkdir -p "$B"

echo "=== [1] copy NON-kernel components from s211 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  cp -f "$S211/$name" "$B/$name"
done
cp -f "$S211/cmdline" "$B/cmdline-base"

echo "=== [2] guard: non-kernel components match s211 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$S211/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "CHANGED vs s211: $name"; exit 1; }
done
echo "  OK"

echo "=== [3] new kernel (CS_VALID guard) ==="
[ "$(md5sum "$NEWK" | cut -d' ' -f1)" = "$KMD5" ] || { echo "KERNEL MD5 MISMATCH: $(md5sum "$NEWK"|cut -d' ' -f1)"; exit 1; }
cp -f "$NEWK" "$B/kernel"
echo "  kernel md5: $(md5sum "$B/kernel" | cut -d' ' -f1)"

echo "=== [4] cmdline identical to s211 ==="
cp -f "$B/cmdline-base" "$B/cmdline"
CL=$(tr -d '\0' < "$B/cmdline")
[ "${#CL}" -le 1024 ] || { echo "CMDLINE TOO LONG"; exit 1; }
echo "  length: ${#CL}"
echo "  tail: ...${CL: -90}"

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s212-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s212-boot.img /root/star26/p2/p2-boot.img "$B/s212-payload.bin" 2>&1 | tail -1

echo "=== [6] verify: cmdline must equal s211, kernel must differ ==="
diff <(python3 "$X" /mnt/c/ios26/s211-boot.img 2>/dev/null | grep 'cmdline:') \
     <(python3 "$X" /mnt/c/ios26/s212-boot.img 2>/dev/null | grep 'cmdline:') && echo "  cmdline IDENTICAL to s211 (good)"
echo "  s211 kernel: $(python3 "$X" /mnt/c/ios26/s211-boot.img 2>/dev/null | grep -i kernel | head -1)"
echo "  s212 kernel: $(python3 "$X" /mnt/c/ios26/s212-boot.img 2>/dev/null | grep -i kernel | head -1)"
sha256sum /mnt/c/ios26/s212-boot.img
ls -la /mnt/c/ios26/s212-boot.img
