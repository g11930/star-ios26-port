#!/bin/bash
# s201 = s200 的 6 个组件原样 + 唯一变量 = kernel 换成 P2 版（PAC 页级自愈改写）。
#
# 为什么重编译：s200 证明显示链路正常但吞吐只有 0.02-1.7 fps，而 arm64e 用户态在
# 无 FEAT_PAuth 的 SM8350 上靠 sleh.c 的 pac_emu 逐条软件模拟 PAC 指令。实测
# input26-service 里 3.7% 的指令会 trap，每 27 条指令一次异常往返 —— 这是吞吐的
# 主要损失。本版在首次 trap 时把整个 4K 页里的 PAC 编码就地改写成等价普通 ARM64
# 指令（retaa->ret, braa->br, blraa->blr, ldraa->ldr/ldur, pacia->nop, pacga->mov），
# 之后硬件直接执行，不再进异常。改写幂等，多核复用。
#
# 闸门：除 kernel 之外任何组件变化都算破单变量，直接退出。
set -e
B=/root/star26/baseline/s201parts
OLD=/root/star26/baseline/s200parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
NEWK=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
NU=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
mkdir -p "$B"

echo "=== [1] copy the 6 unchanged components from s200 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  cp -f "$OLD/$name" "$B/$name"
done
md5sum "$B"/*

echo "=== [2] guard: every copied component must match s200 ==="
for name in loader.efi ramdisk rdimage cmdline memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED: $name"; exit 1; }
done
echo "all six identical to s200"

echo "=== [3] guard: cmdline must still carry the s200 debugging set ==="
CL=$(tr -d '\0' < "$B/cmdline")
echo "cmdline ($(printf '%s' "$CL" | wc -c) B): $CL"
for a in touch_diag=0 touch_lat=1 fb_diff=1; do
  case "$CL" in
    *"$a"*) echo "  $a present" ;;
    *) echo "  $a MISSING"; exit 1 ;;
  esac
done

echo "=== [4] take the freshly built kernel ==="
[ -f "$NEWK" ] || { echo "NO KERNEL at $NEWK"; exit 1; }
NK=$(md5sum "$NEWK" | cut -d' ' -f1)
OK=$(md5sum "$OLD/kernel" | cut -d' ' -f1)
echo "new kernel md5: $NK"
echo "old kernel md5: $OK"
[ "$NK" != "$OK" ] || { echo "KERNEL UNCHANGED -- build did not pick up the patch"; exit 1; }
cp -f "$NEWK" "$B/kernel"
ls -l "$B/kernel"

echo "=== [5] verify the patch is linked in (call sites, not strings) ==="
echo "--- pac_patch globals ---"
llvm-nm "$NU" 2>/dev/null | grep -E '_pac_patch_(enabled|pages|instrs)' || echo "(nm failed)"
echo "--- handle_uncategorized must now call pmap_find_phys + phystokv + cache_sync_page ---"
llvm-objdump -d --disassemble-symbols=_handle_uncategorized "$NU" 2>/dev/null \
  | grep -E 'bl\s+0x[0-9a-f]+ <_(pmap_find_phys|pmap_find_phys_nofault|phystokv|cache_sync_page|current_task)>'

echo "=== [6] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s201-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s201-boot.img /root/star26/p2/p2-boot.img "$B/s201-payload.bin" 2>&1 | tail -1

echo "=== [7] single-variable check: kernel only ==="
echo "--- s201 ---"
python3 "$X" /mnt/c/ios26/s201-boot.img 2>&1 | head -12
echo "--- s200 for comparison ---"
python3 "$X" /mnt/c/ios26/s200-boot.img 2>&1 | head -12
sha256sum /mnt/c/ios26/s201-boot.img
