#!/bin/bash
# mks36.sh -- s36 = s35 with the sbmetal experiment no longer injected into SpringBoard.
# One variable: the injected library list, and only that line of it.
set -e
mkdir -p /root/star26/s36/work
rm -rf /root/star26/s36/work/root
cp -a /root/star26/s34/work/root /root/star26/s36/work/root
cd /root/star26/s36/work
python3 - <<'PY'
p = '/root/star26/s36/work/root/etc/inject.conf'
lines = open(p).read().splitlines(True)
keep, drop = [], []
for l in lines:
    if 'libannibale-sbmetal-experiment.dylib' in l:
        drop.append(l.rstrip('\n'))
    else:
        keep.append(l)
open(p, 'w').writelines(keep)
print('dropped:', drop)
open('/root/star26/s36/work/inject.conf.orig', 'w').writelines(lines)
PY
echo "=== inject.conf now ==="
cat /root/star26/s36/work/root/etc/inject.conf
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s36/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s36 s35 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s36 2>&1 | tail -5
