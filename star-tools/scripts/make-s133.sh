#!/bin/bash
set -e
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837

echo "===== 1) kernel ====="
cp -f $K $BASE/parts/kernel
ls -la $BASE/parts/kernel

echo "===== 2) ramdisk (fw/a660_* goes in plainly) ====="
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw -o $BASE/root19.apfs "annibale=$STG" 2>&1 | tail -1
cp -f $BASE/root19.apfs $BASE/parts/ramdisk
ls -la $BASE/parts/ramdisk

echo "===== 3) payload + reseal ====="
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s133-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s133-boot.img /root/star26/p2/p2-boot.img $BASE/s133-payload.bin 2>&1 | tail -1
cp -f $BASE/s133-boot.img /mnt/c/ios26/s133-boot.img
sha256sum /mnt/c/ios26/s133-boot.img
echo "===== DONE ====="
</bash>
