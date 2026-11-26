#!/bin/bash
# s209 = s208 的全部组件（内核含 GPU IRQ 代码但 gpu_irq=0 不注册，md5 4f832c1）
#        + cmdline 把 pac_patch=0 改成 pac_patch=2。
# 目的：pac_patch=0 纯模拟导致 7.4 亿次陷阱，桌面 1.6fps、锁屏时钟 10 分钟一跳。
#       pac_patch=2 = 只把 RETAA/RETAB 就地改写成 ret（s203 已实测过 mount-phase-2 无 panic）。
# 单变量：相对 s208 只改 pac_patch 的值；内核、其余组件一律不动。
set -e
B=/root/star26/baseline/s209parts
S208=/root/star26/baseline/s208parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py

mkdir -p "$B"

echo "=== [1] copy the 6 components + kernel from s208, cmdline from s207 ==="
for name in loader.efi ramdisk rdimage memsize identity kernel; do
  cp -f "$S208/$name" "$B/$name"
done
cp -f /root/star26/baseline/s207parts/cmdline "$B/cmdline-s207"

echo "=== [2] guard: components must match s208 byte-for-byte ==="
for name in loader.efi ramdisk rdimage memsize identity kernel; do
  A=$(md5sum "$S208/$name" | cut -d' ' -f1)
  C=$(md5sum "$B/$name"  | cut -d' ' -f1)
  [ "$A" = "$C" ] || { echo "CHANGED vs s208: $name"; exit 1; }
done
echo "  all components == s208 (kernel md5 $(md5sum "$B/kernel" | cut -d' ' -f1))"

echo "=== [3] cmdline: s207 + gpu_irq=0 + pac_patch=2 (i.e. s208 with pac_patch 0->2) ==="
CL=$(tr -d '\0' < "$B/cmdline-s207")
case "$CL" in
  *pac_patch*) echo "UNEXPECTED pac_patch already in s207 cmdline"; exit 1 ;;
  *gpu_irq*)   echo "UNEXPECTED gpu_irq already in s207 cmdline";   exit 1 ;;
esac
CL="${CL} gpu_irq=0 pac_patch=2"
echo "cmdline: $CL"
echo "  length: ${#CL} (limit 1024)"
case "$CL" in *"pac_patch=2"*) echo "  pac_patch=2 present";; *) echo "  pac_patch=2 MISSING"; exit 1;; esac
case "$CL" in *"pac_patch=0"*) echo "  pac_patch=0 STILL PRESENT (bad)"; exit 1;; *) echo "  old pac_patch=0 removed";; esac
case "$CL" in *"gpu_irq=0"*)   echo "  gpu_irq=0 present (ISR off)";; *) echo "  gpu_irq=0 MISSING"; exit 1;; esac
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; *) echo "  fb_diff=1 absent (good)";; esac
[ "${#CL}" -le 1024 ] || { echo "CMDLINE TOO LONG"; exit 1; }
printf '%s' "$CL" > "$B/cmdline"

echo "=== [4] repack ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s209-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s209-boot.img /root/star26/p2/p2-boot.img "$B/s209-payload.bin" 2>&1 | tail -1

echo "=== [5] single-variable check: s209 vs s208 ==="
python3 "$X" /mnt/c/ios26/s209-boot.img 2>&1 | grep -E 'cmdline|kernel' | head -3
echo "--- cmdline diff (s208 -> s209) ---"
diff <(python3 "$X" /mnt/c/ios26/s208-boot.img 2>/dev/null | grep 'cmdline:') \
     <(python3 "$X" /mnt/c/ios26/s209-boot.img 2>/dev/null | grep 'cmdline:') || true
sha256sum /mnt/c/ios26/s209-boot.img
ls -la /mnt/c/ios26/s209-boot.img
