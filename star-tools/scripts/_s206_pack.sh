#!/bin/bash
# s206 = s205 的 6 个组件原样 + 唯一变量 = kernel 换成接 GPU 完成中断的版（方案 A 第 2 步）。
#
# 为什么重编译：s205 已证明 fb_diff=1 移除后每帧 17ms、swap 257，但交互仍慢——
# 根因是 AnnibaleGPU.cpp 的 gpuWait() 纯忙等轮询，因为 annibale_gpu_irqs/gpu_pause
# 只有 weak 空桩。本版在 annibale_adreno.c 补真实实现：用 gic_v3_spi_attach 注册
# GPU 完成 SPI（dtb: kgsl_3d0_irq = SPI 0x12c, level），ISR 清 GMU 中断 + 计数，
# gpu_pause 改为中断驱动睡眠，消除 CPU 100% 忙等。
#
# 闸门：除 kernel 之外任何组件变化都算破单变量，直接退出。
set -e
B=/root/star26/baseline/s206parts
OLD=/root/star26/baseline/s205parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
mkdir -p "$B"

echo "=== [1] copy the 6 unchanged components from s205 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] guard: every copied component must match s205 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all six identical to s205"

echo "=== [3] guard: cmdline must still carry the s205 set (no fb_diff=1) ==="
CL=$(tr -d '\0' < "$B/cmdline")
echo "cmdline ($(printf '%s' "$CL" | wc -c) B): $CL"
case "$CL" in
  *"fb_diff=1"*) echo "  fb_diff=1 PRESENT -- must be absent"; exit 1 ;;
  *) echo "  fb_diff=1 absent (good)" ;;
esac

echo "=== [4] take the freshly built kernel ==="
[ -f "$NEWK" ] || { echo "NO KERNEL at $NEWK"; exit 1; }
NK=$(md5sum "$NEWK" | cut -d' ' -f1)
OK=$(md5sum "$OLD/kernel" | cut -d' ' -f1)
echo "new kernel md5: $NK"
echo "old kernel md5: $OK"
[ "$NK" != "$OK" ] || { echo "KERNEL UNCHANGED -- build did not pick up the patch"; exit 1; }
cp -f "$NEWK" "$B/kernel"
ls -l "$B/kernel"

echo "=== [5] verify the patch is linked in (nm, not strings) ==="
llvm-nm "$NU" 2>/dev/null | grep -E '_annibale_gpu_irqs|_annibale_gpu_pause|_annibale_gpu_done|_gpu_completion_isr|_gic_v3_spi_attach'

echo "=== [6] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s206-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s206-boot.img /root/star26/p2/p2-boot.img "$B/s206-payload.bin" 2>&1 | tail -1

echo "=== [7] single-variable check: kernel only ==="
echo "--- s206 ---"
python3 "$X" /mnt/c/ios26/s206-boot.img 2>&1 | head -12
echo "--- s205 for comparison ---"
python3 "$X" /mnt/c/ios26/s205-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s206-boot.img
ls -la /mnt/c/ios26/s206-boot.img
