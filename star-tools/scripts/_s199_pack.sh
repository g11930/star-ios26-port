#!/bin/bash
# s199 = s198 的 6 个组件原样 + 唯一变量 = kernel 换成重编译版。
#
# 为什么重编译：annibale_tl()（bsd/dev/star/annibale_input.c:38）是 tl: s / tl: v /
# tl: l / "milestone: first_frame" 的唯一出口，它结尾用的是 printf()，而这棵树
# config/MASTER:309 开了 CONFIG_NO_PRINTF_STRINGS，libkern.h:191 把 printf 变成
# `do {} while (0)` —— 整条通道被判空，s198 的 touch_lat=1 因此零输出。
# 现在改成逐字符 loader_log_putc()（同目录 goodix_trace 早已这样写并验证过）。
#
# 闸门：除了 kernel 之外任何组件变化都算破单变量，直接退出。
set -e
B=/root/star26/baseline/s199parts
OLD=/root/star26/baseline/s198parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
mkdir -p "$B"

echo "=== [1] copy the 6 unchanged components from s198 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] guard: ramdisk must still be 85c849db42762a065ae2ce4f68a9cad0 ==="
R=$(md5sum "$B/ramdisk" | cut -d' ' -f1)
[ "$R" = "85c849db42762a065ae2ce4f68a9cad0" ] || { echo "RAMDISK MISMATCH: $R"; exit 1; }
echo "ramdisk ok"

echo "=== [3] guard: cmdline must still carry touch_lat=1 (520 B or so) ==="
CL=$(tr -d '\0' < "$B/cmdline")
echo "cmdline: $CL"
echo "cmdline bytes: $(printf '%s' "$CL" | wc -c)"
case "$CL" in
  *touch_lat=1*) echo "touch_lat=1 present" ;;
  *) echo "TOUCH_LAT MISSING"; exit 1 ;;
esac
case "$CL" in
  *touch_diag=0*) echo "touch_diag=0 present" ;;
  *) echo "TOUCH_DIAG MISSING"; exit 1 ;;
esac

echo "=== [4] take the freshly built kernel ==="
[ -f "$NEWK" ] || { echo "NO KERNEL at $NEWK"; exit 1; }
ls -l "$NEWK"
NK=$(md5sum "$NEWK" | cut -d' ' -f1)
OK=$(md5sum "$OLD/kernel" | cut -d' ' -f1)
echo "new kernel md5: $NK"
echo "old kernel md5: $OK"
[ "$NK" != "$OK" ] || { echo "KERNEL UNCHANGED -- build did not pick up the patch"; exit 1; }
cp -f "$NEWK" "$B/kernel"

echo "=== [5] verify the fix is actually inside the linked kernel (nm, not strings) ==="
UN=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
if [ -f "$UN" ]; then
  echo "--- symbol type of _annibale_tl (T = strong text, W = weak) ---"
  /root/star-build/xnu-deps/host/bin/llvm-nm "$UN" 2>/dev/null | grep -w "_annibale_tl" || nm "$UN" 2>/dev/null | grep -w "_annibale_tl" || echo "(nm failed)"
  echo "--- does annibale_tl call loader_log_putc? ---"
  { /root/star-build/xnu-deps/host/bin/llvm-objdump -d --disassemble-symbols=_annibale_tl "$UN" 2>/dev/null \
      || llvm-objdump -d --disassemble-symbols=_annibale_tl "$UN" 2>/dev/null \
      || objdump -d "$UN" 2>/dev/null; } | grep -E "loader_log_putc|bl\s" | head -12
else
  echo "WARN: unstripped.noctf missing"
fi

echo "=== [6] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s199-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s199-boot.img /root/star26/p2/p2-boot.img "$B/s199-payload.bin" 2>&1 | tail -1

echo "=== [7] single-variable check: kernel only ==="
echo "--- s199 ---"
python3 "$X" /mnt/c/ios26/s199-boot.img 2>&1 | head -12
echo "--- s198 for comparison ---"
python3 "$X" /mnt/c/ios26/s198-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s199-boot.img
