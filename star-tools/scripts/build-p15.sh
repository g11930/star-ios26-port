#!/bin/bash
# P15: same payload as P14 but let the kernel keep the CPU much longer, so the
# question "does the system stay up at the lock screen without a GPU" can be
# answered instead of cut short by the loader's return timer.
set -e

SRC=/root/star26/p14/src
DST=/root/star26/p15/src
mkdir -p "$DST"
cp -f "$SRC"/cmdline "$SRC"/identity "$SRC"/loader.efi "$SRC"/memsize "$SRC"/ramdisk "$SRC"/rdimage "$DST"/

printf 'debug=0x10e rootdev=md0 root_apfs=ufs_darwin launchd_unsecure_cache=1 cpus=4 bootcpu=7 small_cores_after=0 ufs=2 ufs_native=1 ufs_write=1 loader_return_after=600' > "$DST/cmdline"

sed 's#/root/star26/p14#/root/star26/p15#g' /root/star26/p14/p14-pack.py > /root/star26/p15/p15-pack.py
chmod +x /root/star26/p15/p15-pack.py
cd /root/star26/p15
python3 p15-pack.py
ls -la /root/star26/p15/p15-boot.img
sha256sum /root/star26/p15/p15-boot.img
