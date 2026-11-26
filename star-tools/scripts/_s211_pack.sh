#!/bin/bash
# s211 = s208 的非内核组件 + 新内核（类别掩码 + FIPS 相位闸门，md5 62f2cff2）
#        + cmdline 与 s210 相同（gpu_irq=0 pac_patch=2）。
# 相对 s210 的唯一变量：内核（s210 无闸门→卡 FIPS；s211 有闸门→先纯模拟过 FIPS，之后提速）。
set -e
B=/root/star26/baseline/s211parts
S208=/root/star26/baseline/s208parts
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
KMD5=62f2cff2ba4ce5d7058b836a387c8098

mkdir -p "$B"

echo "=== [1] copy NON-kernel components from s208 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  cp -f "$S208/$name" "$B/$name"
done
cp -f /root/star26/baseline/s207parts/cmdline "$B/cmdline-s207"

echo "=== [2] guard: non-kernel components match s208 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$S208/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "CHANGED vs s208: $name"; exit 1; }
done
echo "  OK"

echo "=== [3] new kernel (mask + fips gate) ==="
[ "$(md5sum "$NEWK" | cut -d' ' -f1)" = "$KMD5" ] || { echo "KERNEL MD5 MISMATCH: $(md5sum "$NEWK"|cut -d' ' -f1)"; exit 1; }
cp -f "$NEWK" "$B/kernel"
echo "  kernel md5: $(md5sum "$B/kernel" | cut -d' ' -f1)"

echo "=== [4] cmdline identical to s210 ==="
CL=$(tr -d '\0' < "$B/cmdline-s207")
case "$CL" in *pac_patch*|*gpu_irq*) echo "UNEXPECTED in s207 cmdline"; exit 1 ;; esac
CL="${CL} gpu_irq=0 pac_patch=2"
[ "${#CL}" -le 1024 ] || { echo "CMDLINE TOO LONG"; exit 1; }
printf '%s' "$CL" > "$B/cmdline"
echo "  length: ${#CL} | tail: ...${CL: -50}"

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s211-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s211-boot.img /root/star26/p2/p2-boot.img "$B/s211-payload.bin" 2>&1 | tail -1

echo "=== [6] verify: cmdline must equal s210, kernel must differ ==="
diff <(python3 "$X" /mnt/c/ios26/s210-boot.img 2>/dev/null | grep 'cmdline:') \
     <(python3 "$X" /mnt/c/ios26/s211-boot.img 2>/dev/null | grep 'cmdline:') && echo "  cmdline IDENTICAL to s210 (good)"
echo "  s210 kernel: $(python3 "$X" /mnt/c/ios26/s210-boot.img 2>/dev/null | grep -i kernel | head -1)"
echo "  s211 kernel: $(python3 "$X" /mnt/c/ios26/s211-boot.img 2>/dev/null | grep -i kernel | head -1)"
sha256sum /mnt/c/ios26/s211-boot.img
ls -la /mnt/c/ios26/s211-boot.img
