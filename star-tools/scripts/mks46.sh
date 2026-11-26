#!/bin/bash
# mks46.sh -- s46 = s44 + an early klog snapshot taken to a file.
#
# Why: the kernel message buffer is a ring, and by the time starcat runs at t=800 only
# [42.2s .. 571s] survives.  SpringBoard is spawned at 03:03:22, i.e. right at the edge,
# so any dyld complaint about our injected library is already overwritten when we look.
# /dev/klog exists (devfs registers it), so reading it at t=0 into a plain file keeps the
# whole early boot, and a second starcat can print that file at t=800.
#
# inject.conf goes back to s44's exact original (the absolute-path aliases tried in s45
# changed nothing: "sb26:" was still 0 and "pb26:" still 2), so this round has one new
# variable only.
set -e
mkdir -p /root/star26/s46/work
rm -rf /root/star26/s46/work/root
cp -a /root/star26/s45/work/root /root/star26/s46/work/root

# revert inject.conf to the untouched 766-byte original
cp -f /root/star26/s44/work/root/etc/inject.conf /root/star26/s46/work/root/etc/inject.conf
echo "== inject.conf =="
md5sum /root/star26/s46/work/root/etc/inject.conf; wc -c < /root/star26/s46/work/root/etc/inject.conf

cat > /root/star26/s46/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s46: the first line snapshots /dev/klog to a file before the ring buffer discards the
# early boot (SpringBoard is spawned around the edge of what survives to t=800).
# The last-but-one line prints that snapshot back at t=800.
/annibale/bin/starcat -n 400000 /dev/klog > /private/var/tmp/klog0.txt &
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/lsprobe 120 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 600 &
/annibale/bin/lsprobe 840 &
/annibale/bin/starcat -t 780 -n 400000 /private/var/tmp/klog0.txt &
/annibale/bin/starcat -t 820 -n 60000 -p backboardd /private/var/mobile/Library/Logs/CrashReporter &
EOF
echo "== rc.jobs =="
cat /root/star26/s46/work/root/etc/rc.jobs

cd /root/star26/s46/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s46/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s46 s45 "" loader_return_after=900 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s46 2>&1 | tail -3
ls -l /root/star26/s46/s46-boot.img
