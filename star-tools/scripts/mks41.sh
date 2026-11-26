#!/bin/bash
# mks41.sh -- s41 = s40 with the clock fixed: the kernel was returning at 200 s
# (loader_return_after), and the one boot on record that reached StartWindowServer ran to 590 s.
# 900 s this time, and the probes are placed late enough to see it.
set -e
mkdir -p /root/star26/s41/work
rm -rf /root/star26/s41/work/root
cp -a /root/star26/s40/work/root /root/star26/s41/work/root
cd /root/star26/s41/work
python3 - <<'PY'
p = '/root/star26/s41/work/root/etc/rc.jobs'
lines = open(p).read().splitlines(True)
keep = [l for l in lines if 'starcat' not in l and 'lsprobe' not in l]
keep.append('/annibale/bin/lsprobe 120 300 600 840 &\n')
keep.append('/annibale/bin/starcat -t 800 -n 30000 -p backboardd '
            '/private/var/mobile/Library/Logs/CrashReporter &\n')
open(p, 'w').writelines(keep)
print(''.join(keep[-3:]))
PY
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s41/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s41 s40 "" loader_return_after=900 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s41 2>&1 | tail -4
