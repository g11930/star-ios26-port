#!/bin/bash
# mks37.sh -- s37 = s36 plus userland probes in rc.jobs: MobileGestalt, CoreGraphics/IOSurface,
# the window server's drawables, Metal, and the frame counter.  Diagnostics only: the system's
# own jobs are untouched.
set -e
mkdir -p /root/star26/s37/work
rm -rf /root/star26/s37/work/root
cp -a /root/star26/s36/work/root /root/star26/s37/work/root
cd /root/star26/s37/work
cat >> root/etc/rc.jobs <<'EOF'
/annibale/bin/mg_test &
/annibale/bin/cg_test &
/annibale/bin/drawable_test &
/annibale/bin/metal_dev &
/annibale/bin/framewatch &
EOF
echo "=== rc.jobs tail ==="
tail -8 root/etc/rc.jobs
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s37/root.apfs annibale=root 2>&1 | tail -2
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s37 s36 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s37 2>&1 | tail -4
