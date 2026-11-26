#!/bin/bash
# mks39.sh -- s39 = s38 plus starcat, told to print the newest crash report on the data volume
# at t=150 s.  The crash reports of backboardd are what the last run found; this reads one.
set -e
mkdir -p /root/star26/s39/work
rm -rf /root/star26/s39/work/root
cp -a /root/star26/s38/work/root /root/star26/s39/work/root
cp -f /root/star26/s39/work/starcat /root/star26/s39/work/root/bin/starcat
chmod 755 /root/star26/s39/work/root/bin/starcat
cd /root/star26/s39/work
cat >> root/etc/rc.jobs <<'EOF'
/annibale/bin/starcat -t 100 -n 48000 /private/var/mobile/Library/Logs/CrashReporter &
/annibale/bin/lsprobe 150 &
EOF
echo "=== rc.jobs tail ==="
tail -6 root/etc/rc.jobs
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s39/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s39 s38 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s39 2>&1 | tail -4
