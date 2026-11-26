#!/bin/bash
# s207 = s205 的 6 个组件 + 新内核（含 gpu_irq 开关），cmdline 加 gpu_irq=0。
# 目的：隔离 3 秒崩溃——gpu_irq=0 跳过 ISR 注册，只保留 gpu_pause 睡眠。
# 若不崩，证明崩溃由 ISR 注册（gic_v3_spi_attach / ISR）引起。
set -e
B=/root/star26/baseline/s207parts
OLD=/root/star26/baseline/s205parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
mkdir -p "$B"

echo "=== [1] copy the 6 unchanged components from s205 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done

echo "=== [2] guard: every copied component must match s205 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all identical to s205 (cmdline intentionally edited below)"

echo "=== [3] cmdline: add gpu_irq=0 ==="
CL=$(tr -d '\0' < "$B/cmdline")
CL="${CL} gpu_irq=0"
echo "cmdline: $CL"
case "$CL" in *"gpu_irq=0"*) echo "  gpu_irq=0 present";; *) echo "  gpu_irq=0 MISSING"; exit 1;; esac
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT"; exit 1;; *) echo "  fb_diff=1 absent (good)";; esac

echo "=== [4] take the freshly built kernel ==="
[ -f "$NEWK" ] || { echo "NO KERNEL"; exit 1; }
NK=$(md5sum "$NEWK" | cut -d' ' -f1)
echo "new kernel md5: $NK"
cp -f "$NEWK" "$B/kernel"

echo "=== [5] verify gpu_irq switch symbol in kernel (nm) ==="
llvm-nm "$NU" 2>/dev/null | grep -E '_annibale_gpu_irqs|_annibale_gpu_pause|_attach_gpu_completion_irq|_gpu_completion_isr|_gic_v3_spi_attach'

echo "=== [6] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s207-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s207-boot.img /root/star26/p2/p2-boot.img "$B/s207-payload.bin" 2>&1 | tail -1

echo "=== [7] single-variable check ==="
python3 "$X" /mnt/c/ios26/s207-boot.img 2>&1 | grep -E 'cmdline|kernel' | head -3
sha256sum /mnt/c/ios26/s207-boot.img
ls -la /mnt/c/ios26/s207-boot.img
