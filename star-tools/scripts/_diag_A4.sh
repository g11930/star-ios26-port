#!/bin/bash
set +e
echo "########## A. ramfs vnops fsync ##########"
grep -rn "fsync\|VNOP_FSYNC\|vnop_fsync" /root/star26/star-native/bsd/miscfs/ramfs/*.c /root/star26/star-native/bsd/miscfs/ramfs/*.inc 2>/dev/null | head -40
echo "########## B. ramfs_disk_sync_impl ##########"
grep -n "ramfs_disk_sync_impl\|ramfs_disk_sync\|EBUSY\|ml_get_interrupts_enabled\|VNOP_FSYNC" /root/star26/star-native/bsd/miscfs/ramfs/ramfs_disk.inc | head -40
echo "########## C. ramfs vnode op table ##########"
grep -rn "vnop_fsync\|nop_fsync\|err_fsync" /root/star26/star-native/bsd/miscfs/ramfs/ 2>/dev/null | head -30
echo "########## D. s55/s57 logdump fsync context (strings around) ##########"
for f in /root/star26/s55/*.bin /root/star26/s57/*.bin /root/star26/s58/*.bin; do
  [ -f "$f" ] || continue
  echo "--- $f ---"
  strings -a "$f" 2>/dev/null | grep -i "fsync\|diagnostics\|persist\|could not\|failed to\|logd.*log" | head -25
done
echo "########## E. where logd writes: persist path in logd strings ##########"
grep -aon "/private/var/db/diagnostics\|Persist\|logdata\.tracev3\|/var/db/diagnostics" /root/star26/s58/*.bin 2>/dev/null | head -20
