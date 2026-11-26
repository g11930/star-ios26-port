#!/bin/bash
set -e
BASE=/root/star26/s111
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
N=${N:-135}

cp -f $K $BASE/parts/kernel
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s$N-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s$N-boot.img /root/star26/p2/p2-boot.img $BASE/s$N-payload.bin 2>&1 | tail -1
cp -f $BASE/s$N-boot.img /mnt/c/ios26/s$N-boot.img
sha256sum /mnt/c/ios26/s$N-boot.img
</bash>
