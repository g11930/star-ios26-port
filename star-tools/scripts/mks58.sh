#!/bin/bash
# mks58.sh -- s58 = s57 with ONE kernel change: APFS fsync now returns ENOTSUP instead of 0.
#
# s57's 20 ms tracer proved logd dies in fsync (pc=fsync lr=logd+0x15598) every time.  The APFS
# vnode table made fsync a no-op that returned 0 ("success") while every write returned ENOTSUP
# (read-only).  That impossible state -- a write fails but its fsync "succeeds" -- is what logd's
# assert trips on, and it __builtin_trap()s into SIGTRAP.  This round only changes apfs_vnops.c's
# fsync slot from nop_fsync to err_fsync, so fsync and write agree: the filesystem is read-only.
# The probe, inject.conf and cmdline are byte-identical to s57 so the only variable is the kernel.
set -e
U=/root/star26/hackios-xnu-userland/userland

mkdir -p /root/star26/s58/work
rm -rf /root/star26/s58/work/root
cp -a /root/star26/s57/work/root /root/star26/s58/work/root

echo "=== root/ libs and inject.conf unchanged from s57 ==="
cat /root/star26/s58/work/root/etc/inject.conf

echo "=== root.apfs (unchanged content) ==="
cd /root/star26/s58/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s58/root.apfs annibale=root 2>&1 | tail -1

echo "=== boot image (kernel from current BUILD, with the fsync fix) ==="
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s58 s57 "" 2>&1 | tail -6
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s58 2>&1 | tail -4
echo "== cmdline =="
tr -d '\0' < /root/star26/s58/parts/cmdline
echo
ls -l /root/star26/s58/s58-boot.img
