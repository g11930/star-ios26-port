#!/bin/bash
# mks40.sh -- s40 = s39 with starcat pointed at backboardd's own crash report: the daemon
# SpringBoard waits on.  Everything else unchanged.
set -e
mkdir -p /root/star26/s40/work
rm -rf /root/star26/s40/work/root
cp -a /root/star26/s39/work/root /root/star26/s40/work/root
cp -f /root/star26/s39/work/starcat /root/star26/s40/work/root/bin/starcat
chmod 755 /root/star26/s40/work/root/bin/starcat
cd /root/star26/s40/work
# drop the probe lines s39 carried, keep one read of backboardd's newest report
python3 - <<'PY'
p = '/root/star26/s40/work/root/etc/rc.jobs'
lines = open(p).read().splitlines(True)
keep = [l for l in lines
        if 'starcat' not in l and 'lsprobe' not in l and 'svc_test' not in l]
keep.append('/annibale/bin/starcat -t 90 -n 70000 -p backboardd '
            '/private/var/mobile/Library/Logs/CrashReporter &\n')
open(p, 'w').writelines(keep)
print(''.join(keep[-3:]))
PY
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s40/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s40 s39 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s40 2>&1 | tail -4
