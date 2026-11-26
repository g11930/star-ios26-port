#!/bin/bash
# mks66.sh -- s66 = s65 kernel + s58 ramdisk + starcat dumping the newest logd crash report.
#
# Goal: capture WHY logd dies (SIGTRAP/xstat 5, 16 times per boot) by having a
# static starcat job print /private/var/mobile/Library/Logs/CrashReporter/logd-*.ips
# into the kernel log at t=180s.  No kernel change, no cmdline change.
# The ONLY delta vs s65 is the ramdisk content (one extra rc.jobs line; the
# starcat binary already exists in the s58 root tree at bin/starcat).
set -e
U=/root/star26/hackios-xnu-userland/userland

mkdir -p /root/star26/s66/work
rm -rf /root/star26/s66/work/root
cp -a /root/star26/s58/work/root /root/star26/s66/work/root

# starcat binary is already at root/bin/starcat (mapped to /annibale/bin/starcat).
ls -l /root/star26/s66/work/root/bin/starcat

cat > /root/star26/s66/work/root/etc/rc.jobs <<'EOF'
# s66: keep the s52 lsprobe windows, plus starcat to dump the newest logd crash
# report into the kernel log at t=180s (logd dies ~03:03:30 with SIGTRAP).
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 150 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 480 &
/annibale/bin/starcat -t 180 -n 60000 -p logd /private/var/mobile/Library/Logs/CrashReporter &
EOF
echo "=== new rc.jobs ==="
cat /root/star26/s66/work/root/etc/rc.jobs

echo "=== root.apfs ==="
cd /root/star26/s66/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s66/root.apfs annibale=root 2>&1 | tail -1

echo "=== boot image: s65 kernel + s66 ramdisk, cmdline byte-identical ==="
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s66 s65 "" 2>&1 | tail -4
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s66 2>&1 | tail -6
echo "== cmdline =="
tr -d '\0' < /root/star26/s66/parts/cmdline
echo
echo "== kernel md5 (must equal s65) =="
md5sum /root/star26/s66/parts/kernel /root/star26/s65/parts/kernel
