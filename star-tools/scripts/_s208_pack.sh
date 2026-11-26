#!/bin/bash
# s208 = s207 的 6 个组件 + s207 的同一个内核（含 GPU IRQ 代码，md5 4f832c1）+ cmdline 只多 pac_patch=0。
# 目的：s207 已证明 3 秒崩溃 = ISR 注册；s207 又在 55.7s 崩在 mount-phase-2
#       "boot task is not a platform binary"，日志有 24 页 / 3231 条 pac: page 改写，
#       与已放弃的 s201 PAC 页改写回归完全同签名。pac_patch=0 关闭页改写（s202 已验证可完整启动）。
# 单变量：相对 s207 只增加 pac_patch=0；内核、其余组件一律不动。
set -e
B=/root/star26/baseline/s208parts
S207=/root/star26/baseline/s207parts
OLD=/root/star26/baseline/s205parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py

mkdir -p "$B"

echo "=== [1] copy the 6 unchanged components + kernel from s207 ==="
for name in loader.efi ramdisk rdimage memsize identity kernel; do
  cp -f "$S207/$name" "$B/$name"
done

echo "=== [2] guard: components must match s205, kernel must match s207 ==="
for name in loader.efi ramdisk rdimage memsize identity; do
  A=$(md5sum "$OLD/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "COMPONENT CHANGED vs s205: $name"; exit 1; }
done
K_S207=$(md5sum "$S207/kernel" | cut -d' ' -f1)
K_NEW=$(md5sum "$B/kernel"   | cut -d' ' -f1)
[ "$K_S207" = "$K_NEW" ] || { echo "KERNEL CHANGED vs s207"; exit 1; }
echo "  components == s205 ; kernel == s207 (md5 $K_NEW)"

echo "=== [3] cmdline = s207's cmdline + gpu_irq=0 + pac_patch=0 (only new arg: pac_patch=0) ==="
CL=$(tr -d '\0' < "$S207/cmdline")
CL="${CL} gpu_irq=0 pac_patch=0"
echo "cmdline: $CL"
echo "  length: ${#CL} (limit 1024)"
case "$CL" in *"gpu_irq=0"*)   echo "  gpu_irq=0 present";;   *) echo "  gpu_irq=0 MISSING"; exit 1;; esac
case "$CL" in *"pac_patch=0"*) echo "  pac_patch=0 present";; *) echo "  pac_patch=0 MISSING"; exit 1;; esac
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; *) echo "  fb_diff=1 absent (good)";; esac
[ "${#CL}" -le 1024 ] || { echo "CMDLINE TOO LONG"; exit 1; }

echo "=== [4] verify kernel still carries the GPU IRQ + pac code ==="
llvm-nm "$B/kernel" 2>/dev/null | grep -E '_annibale_gpu_irqs|_annibale_gpu_pause|_gic_v3_spi_attach' || true
echo -n "  pac_patch string count: "; strings -a "$B/kernel" | grep -c '^pac_patch$' || true
echo -n "  pac: page string count:  "; strings -a "$B/kernel" | grep -c 'pac: page' || true

echo "=== [5] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s208-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s208-boot.img /root/star26/p2/p2-boot.img "$B/s208-payload.bin" 2>&1 | tail -1

echo "=== [6] single-variable check: s208 vs s207 ==="
python3 "$X" /mnt/c/ios26/s208-boot.img 2>&1 | grep -E 'cmdline|kernel' | head -3
echo "--- compare with s207 ---"
python3 "$X" /mnt/c/ios26/s207-boot.img 2>&1 | grep -E 'cmdline|kernel' | head -3
echo "--- cmdline diff (s207 -> s208) ---"
diff <(python3 "$X" /mnt/c/ios26/s207-boot.img 2>/dev/null | grep 'cmdline:') \
     <(python3 "$X" /mnt/c/ios26/s208-boot.img 2>/dev/null | grep 'cmdline:') || true
sha256sum /mnt/c/ios26/s208-boot.img
ls -la /mnt/c/ios26/s208-boot.img
