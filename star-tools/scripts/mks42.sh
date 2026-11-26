#!/bin/bash
# mks42.sh -- s42 = s41 with exactly one change: /lib/libannibaleair.dylib is
# replaced by the build from hackios-xnu-kernel/xnu-deps/build/mesa/build-star26
# (2026-11-14 05:45), whose src/compiler/air/air_metal_lowering.inc (05:44) knows
# the tex/half cases that produce backboardd's
#   COREANIMATION code=4 "softpipe half lowering does not support instruction type 3"
# Exported symbol set is identical old vs new (57/57), so it is a drop-in.
set -e
SRC=/root/star26/hackios-xnu-kernel/xnu-deps/build/mesa/build-star26/src/gallium/drivers/freedreno/libannibaleair.dylib
mkdir -p /root/star26/s42/work
rm -rf /root/star26/s42/work/root
cp -a /root/star26/s41/work/root /root/star26/s42/work/root
echo "== before =="
md5sum /root/star26/s42/work/root/lib/libannibaleair.dylib
cp -f "$SRC" /root/star26/s42/work/root/lib/libannibaleair.dylib
echo "== after  =="
md5sum /root/star26/s42/work/root/lib/libannibaleair.dylib
ls -l /root/star26/s42/work/root/lib/libannibaleair.dylib
echo "== air cache present? =="
ls -ld /root/star26/s42/work/root/private/var/db/annibale-ir3cache 2>/dev/null || echo "  (none)"
cd /root/star26/s42/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s42/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s42 s41 "" loader_return_after=900 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s42 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s42/parts/cmdline
echo
ls -l /root/star26/s42/s42-boot.img
