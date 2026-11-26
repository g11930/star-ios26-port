#!/bin/bash
# mks38.sh -- s38 = s37 with the probe list replaced by two instruments that answer the
# questions the last run left: whether XPC itself works (svc_test), and what the process
# table and the crash directory look like later in the boot (lsprobe at 30/90/170 s).
set -e
mkdir -p /root/star26/s38/work
rm -rf /root/star26/s38/work/root
cp -a /root/star26/s36/work/root /root/star26/s38/work/root
cd /root/star26/s38/work
cat >> root/etc/rc.jobs <<'EOF'
/annibale/bin/svc_test &
/annibale/bin/lsprobe 30 90 170 &
EOF
echo "=== rc.jobs tail ==="
tail -6 root/etc/rc.jobs
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s38/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s38 s37 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s38 2>&1 | tail -4
