#!/bin/bash
# mks50.sh -- s50 = s49 + the kernel that answers kern.annibale.say.
#
# The only change against s49 is the kernel image: bsd/dev/star/star_platform_stubs.c now
# registers kern.annibale.say (star_say_sysctl -> IOLog "say PID TEXT").  Every annibale
# library in the iOS 26 userland reports through that sysctl instead of standard error, so
# until now their diagnostics were dropped with ENOENT:
#   inject_sb26.c          "sb26: loaded in %s uuid=%s"      <- answers whether SpringBoard
#                                                              got DYLD_INSERT_LIBRARIES
#   sb_metal_registration_sequence.inc                        <- answers whether backboardd's
#                                                              Metal registration ran
#   inject_sb26_layers.c / inject_sb26_rate.c / inject_posterboard.c / inject_media.c /
#   xpcwatch.c
#
# cmdline is inherited from s49 unchanged, so metal=1 stays and this boot differs from s49
# in the kernel and in nothing else.
set -e
mkdir -p /root/star26/s50/work
rm -rf /root/star26/s50/work/root
cp -a /root/star26/s49/work/root /root/star26/s50/work/root

cat > /root/star26/s50/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s50: the kernel answers kern.annibale.say now, so the annibale libraries in SpringBoard,
# backboardd and PosterBoard can finally be read.  metal=1 is still on (s49).
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 150 &
/annibale/bin/lsprobe 300 &
/annibale/bin/lsprobe 480 &
/annibale/bin/starcat -t 540 -n 60000 -p backboardd /private/var/mobile/Library/Logs/CrashReporter &
EOF

cd /root/star26/s50/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s50/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s50 s49 "" 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s50 2>&1 | tail -3
echo "== cmdline =="
tr -d '\0' < /root/star26/s50/parts/cmdline
echo
echo "== kernel in s50 =="
sha256sum /root/star26/s50/parts/kernel
grep -c "a line for the kernel log" /root/star26/s50/parts/kernel 2>/dev/null || true
ls -l /root/star26/s50/s50-boot.img
