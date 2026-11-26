#!/bin/bash
set +e
echo "########## A. init.c mount / bind / diagnostics ##########"
grep -n "mount\|bind\|diagnostics\|md0\|ramfs\|var/db\|/private/var\|ANNFS\|ufs_darwin" /root/star26/hackios-xnu-userland/userland/src/boot/init.c | head -120
echo "########## B. rc.jobs ##########"
cat /root/star26/hackios-xnu-userland/userland/jobs/rc.jobs
echo "########## C. var.skel diagnostics? ##########"
grep -n "diagnostics\|db\|var/db\|log" /root/star26/s54/work/root/etc/var.skel | head -40
echo "########## D. logd-related strings in s58 logdump ##########"
grep -aon "diagnostics\|persist\|fsync\|logd\[\|syslog" /root/star26/s58/*.bin 2>/dev/null | head -40
echo "########## E. bindfs available in kernel? ##########"
ls -la /root/star26/star-native/bsd/miscfs/bindfs/ 2>/dev/null
echo "########## F. md0/ramfs in kernel conf ##########"
grep -n "RAMFS\|md0\|ramdisk\|bindfs" /root/star26/star-native/bsd/conf/files /root/star26/star-native/bsd/conf/MASTER /root/star26/star-native/config/MASTER 2>/dev/null | head -40
