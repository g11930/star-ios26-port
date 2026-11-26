#!/bin/bash
# mks47.sh -- s47 = s46 + applog, with a short window so the early log survives.
#
# Two facts from kern_exec.c:
#   * exec_applog_oslog() adds OS_ACTIVITY_DT_MODE / ACTIVITY_LOG_STDERR / CFLOG_FORCE_STDERR
#     to a program's environment when boot-args say  applog=1 applog_name=NAME,...
#     (applog>=2 = every program, much slower).  That routes os_log and CFLog to standard
#     error, which for a launchd job is /dev/console, i.e. the kernel message buffer --
#     bypassing logd, which is stuck in a crash loop and swallows everything else.
#   * The klog ring only keeps ~530 s.  SpringBoard is spawned at uptime ~40 s, so with
#     loader_return_after=900 its startup is long overwritten.  300 s still covers init,
#     launchd, SpringBoard and backboardd startup, and keeps them in the buffer.
#
# Also drops the /dev/klog snapshot attempt from s46: that node exists in devfs but
# cannot be opened, and rc.jobs is not a shell so ">" was passed to starcat as a path.
set -e
mkdir -p /root/star26/s47/work
rm -rf /root/star26/s47/work/root
cp -a /root/star26/s46/work/root /root/star26/s47/work/root

cat > /root/star26/s47/work/root/etc/rc.jobs <<'EOF'
# interactive: no synthetic touches, for a person holding the phone.
#
# s47: applog is a boot-arg (see exec_applog_oslog in bsd/kern/kern_exec.c), so the
# os_log of SpringBoard and backboardd goes to standard error -> /dev/console -> klog
# without logd.  The window is 300 s so that stays in the ring buffer.
/annibale/bin/annsh &
/annibale/bin/trollstorehelper watch &
/annibale/bin/lsprobe 60 &
/annibale/bin/lsprobe 120 &
/annibale/bin/lsprobe 240 &
/annibale/bin/starcat -t 260 -n 60000 -p backboardd /private/var/mobile/Library/Logs/CrashReporter &
EOF
echo "== rc.jobs =="
cat /root/star26/s47/work/root/etc/rc.jobs

cd /root/star26/s47/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s47/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s47 s46 "" \
	loader_return_after=300 applog=1 applog_name=SpringBoard,backboardd 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s47 2>&1 | tail -3
echo "== cmdline =="
tr -d '\0' < /root/star26/s47/parts/cmdline
echo
ls -l /root/star26/s47/s47-boot.img
