#!/bin/bash
# mks48.sh -- s48 = s47 with applog 1 -> 2.  One variable.
#
# s47 proved the boot-arg arrives intact (launchd's own log prints the whole boot-args
# string, which ends with "applog=1 applog_name=SpringBoard,backboardd"), yet not one
# line of SpringBoard's os_log appeared -- only launchd's, which goes to the console
# anyway as pid 1.  exec_applog_oslog() matches with the same
# imgp->ip_ndp->ni_cnd.cn_nameptr that exec_inject_env() uses, so both failing together
# is consistent: that field does not carry "SpringBoard" at this point.
#
# applog>=2 returns true before any matching, so every program's os_log and CFLog go to
# standard error -> /dev/console -> klog.  It costs speed ("a much slower system") but
# the window is 300 s.
set -e
mkdir -p /root/star26/s48/work
rm -rf /root/star26/s48/work/root
cp -a /root/star26/s47/work/root /root/star26/s48/work/root

cd /root/star26/s48/work
python3 /root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py -z --plain fw \
	-o /root/star26/s48/root.apfs annibale=root 2>&1 | tail -1
cd /root/star26/star-native
python3 /mnt/d/桌面/star26-deps/scripts/make-boot.py s48 s47 "" \
	loader_return_after=300 applog=2 2>&1 | tail -3
bash /mnt/d/桌面/star26-deps/scripts/repack-ramdisk.sh s48 2>&1 | tail -3
echo "== cmdline =="
tr -d '\0' < /root/star26/s48/parts/cmdline
echo
ls -l /root/star26/s48/s48-boot.img
