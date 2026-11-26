#!/bin/bash
set -e
BASE=/root/star26/s111
K=/root/star26/star-native/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837

cp -f $K $BASE/parts/kernel
python3 - <<'PY'
p = '/root/star26/s111/parts/cmdline'
s = open(p).read().strip()
w = [x for x in s.split() if not x.startswith('gpu_nomeasure=')]
w.append('gpu_nomeasure=1')
open(p, 'w').write(' '.join(w))
print('cmdline', len(' '.join(w)))
PY

python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s134-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s134-boot.img /root/star26/p2/p2-boot.img $BASE/s134-payload.bin 2>&1 | tail -1
cp -f $BASE/s134-boot.img /mnt/c/ios26/s134-boot.img
sha256sum /mnt/c/ios26/s134-boot.img
</bash>
