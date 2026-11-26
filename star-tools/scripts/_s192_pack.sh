#!/bin/bash
# s192 = s175 parts + ramdisk with fixed icon-fill dylib (context non-null, 9 passes, diag).
set -e
NEW=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
ROOT=/root/star26/s111/work/rootbuild/root
DST=$ROOT/lib/libannibale-sb26.dylib
B=/root/star26/baseline/s175parts
X=/mnt/d/桌面/star26-deps/scripts/xnup_info.py

echo "=== [1] remove stray .bak from staged root, replace dylib ==="
rm -f "$ROOT/lib/libannibale-sb26.dylib.s175-pre-iconfill.bak"
cp -f "$NEW" "$DST"; chmod 755 "$DST"
md5sum "$DST"

echo "=== [2] rebuild ramdisk ==="
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw -o /root/star26/s111/root19.apfs "annibale=$ROOT" 2>&1 | tail -1
cp -f /root/star26/s111/root19.apfs /root/star26/s111/parts/ramdisk
md5sum /root/star26/s111/parts/ramdisk

echo "=== [3] rebuild from s175 parts (kernel/cmdline/etc unchanged) ==="
cp -f /root/star26/s111/parts/ramdisk "$B/ramdisk"
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py \
  -o "$B/s192-payload.bin" loader.efi="$B/loader.efi" kernel="$B/kernel" ramdisk="$B/ramdisk" \
  rdimage="$B/rdimage" \
  --cmdline "$(cat "$B/cmdline" | tr -d '\0')" --memsize "$(cat "$B/memsize" | tr -d '\0')" \
  --identity "$(cat "$B/identity" | tr -d '\0')" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py \
  -o /mnt/c/ios26/s192-boot.img /root/star26/p2/p2-boot.img "$B/s192-payload.bin" 2>&1 | tail -1

echo "=== [4] verify single variable ==="
python3 "$X" /mnt/c/ios26/s192-boot.img 2>&1 | grep -E "kernel|ramdisk|cmdline" | head -3
sha256sum /mnt/c/ios26/s192-boot.img
