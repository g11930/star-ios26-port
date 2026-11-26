#!/bin/bash
set -e
BASE=/root/star26/s111
STG=$BASE/work/rootbuild/root
U=/root/star26/hackios-xnu-userland

echo "===== 1) cmdline 加 fbpaint=1 ====="
python3 - <<'PY'
p = '/root/star26/s111/parts/cmdline'
s = open(p).read().strip()
if 'fbpaint' not in s:
    s = s + ' fbpaint=1'
open(p, 'w').write(s)
print(len(s), s[-120:])
PY

echo "===== 2) ramdisk 不变，只重打 payload ====="
cp -f $BASE/root18.apfs $BASE/parts/ramdisk
python3 /root/star26/hackios-xnu-kernel/xnuloader/mkpayload.py -o $BASE/s131-payload.bin loader.efi=$BASE/parts/loader.efi kernel=$BASE/parts/kernel ramdisk=$BASE/parts/ramdisk rdimage=$BASE/parts/rdimage --cmdline "$(cat $BASE/parts/cmdline)" --memsize "$(cat $BASE/parts/memsize)" --identity "$(cat $BASE/parts/identity)" 2>&1 | tail -1
python3 /root/star26/hackios-xnu-kernel/tools/reseal-loader-img.py -o $BASE/s131-boot.img /root/star26/p2/p2-boot.img $BASE/s131-payload.bin 2>&1 | tail -1
cp -f $BASE/s131-boot.img /mnt/c/ios26/s131-boot.img
sha256sum /mnt/c/ios26/s131-boot.img
echo "===== DONE ====="
</bash>
