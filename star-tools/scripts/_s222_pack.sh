#!/bin/bash
# s222 = s221 with ONLY the kernel replaced (4k shared-region-slide pager patch).
# Single variable vs s221: kernel pager patch. All other components + cmdline identical.
set -e
B=/root/star26/baseline/s222parts
S221=/root/star26/baseline/s221parts
KNEW=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py
IMG=/mnt/c/ios26/s222-boot.img

mkdir -p "$B"

echo "=== [1] all components from s221 (single variable = kernel) ==="
for name in loader.efi ramdisk rdimage memsize identity; do cp -f "$S221/$name" "$B/$name"; done
cp -f "$KNEW" "$B/kernel"
echo -n "  kernel md5  "; md5sum "$B/kernel" | cut -d' ' -f1
echo -n "  ramdisk md5 "; md5sum "$B/ramdisk" | cut -d' ' -f1

echo "=== [2] kernel carries pager patch symbols ==="
NM=/usr/bin/llvm-nm
U=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837.unstripped.noctf
"$NM" "$U" 2>/dev/null | grep -wq '_vm_shared_region_slide_part_v5' || { echo "  MISSING slide_part_v5"; exit 1; }
echo "  FOUND: _vm_shared_region_slide_part_v5"
# 反汇编确认 data_request 里有对 slide_part_v5 的调用
CALLS=$(llvm-objdump -d --disassemble-symbols=_shared_region_pager_data_request \
  /root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837 2>/dev/null \
  | grep -c '<_vm_shared_region_slide_part_v5>')
echo "  data_request -> slide_part_v5 calls: $CALLS"
[ "$CALLS" -ge 2 ] || { echo "  expected >=2 calls"; exit 1; }

echo "=== [3] cmdline: EXACT copy from s221 image (zero edits) ==="
# info 行显示的 600 = payload 字节数(含 mkpayload 补的结尾 \0)；这里提取的是 599 字符正文
python3 "$X" /mnt/c/ios26/s221-boot.img 2>/dev/null \
  | sed -n 's/^    cmdline: //p' | tr -d '\n\r\0' > "$B/cmdline"
CL=$(cat "$B/cmdline")
echo "  length ${#CL} (body, limit 1024), md5 $(md5sum "$B/cmdline" | cut -d' ' -f1)"
# 交叉验证：用 s221 打包公式(s207 基线 + PAC args)重建，必须与镜像提取逐字节一致
CL_REBUILD="$(tr -d '\0' < /root/star26/baseline/s207parts/cmdline) gpu_irq=0 pac_patch=2 pac_patch_delay=900 pac_patch_budget=256 pac_patch_burst=8"
[ "$CL" = "$CL_REBUILD" ] || { echo "  cmdline MISMATCH vs s221 formula, ABORT"; echo "  rebuilt len ${#CL_REBUILD}"; exit 1; }
echo "  EXACT MATCH with s221 formula"
[ "${#CL}" -gt 1024 ] && { echo "  TOO LONG"; exit 1; }
case "$CL" in *"fb_diff=1"*) echo "  fb_diff=1 PRESENT (bad)"; exit 1;; esac
echo "  $CL" | tail -c 160

echo "=== [4] repack + reseal ==="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s222-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$CL" --memsize "$(tr -d '\0' < "$B/memsize")" \
  --identity "$(tr -d '\0' < "$B/identity")" 2>&1 | tail -2
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o "$IMG" /root/star26/p2/p2-boot.img "$B/s222-payload.bin" 2>&1 | tail -2

echo "=== [5] verify image ==="
ls -l "$IMG"
md5sum "$IMG"
python3 "$X" "$IMG" 2>/dev/null | grep -E 'cmdline|kernel|ramdisk|payload' | head -8
echo "DONE"
