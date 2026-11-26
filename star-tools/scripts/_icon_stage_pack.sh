#!/bin/bash
# Replace sb26 dylib in staged root, then rebuild ramdisk + payload + boot.img (N=191).
set -e
NEW=/root/star26/hackios-xnu-userland/userland/obj/libannibale-sb26.dylib
ROOT=/root/star26/s111/work/rootbuild/root
DST=$ROOT/lib/libannibale-sb26.dylib
BASE=/root/star26/s111
N=191

echo "=== [1] backup original dylib + replace ==="
cp -f "$DST" "$DST.s175-pre-iconfill.bak"
cp -f "$NEW" "$DST"
chmod 755 "$DST"
md5sum "$DST" "$NEW"

echo "=== [2] rebuild ramdisk (root19.apfs) ==="
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root19.apfs "annibale=$ROOT" 2>&1 | tail -2
cp -f $BASE/root19.apfs $BASE/parts/ramdisk
ls -la $BASE/parts/ramdisk

echo "=== [3] rebuild payload + boot.img ==="
cd /mnt/d/桌面/star26-deps/scripts
N=$N bash ./make-s139.sh 2>&1 | grep -E 'boot.img|sha256' | tail -3
echo "=== [4] final ==="
ls -la /mnt/c/ios26/s${N}-boot.img
sha256sum /mnt/c/ios26/s${N}-boot.img
