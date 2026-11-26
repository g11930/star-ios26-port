#!/bin/bash
set +e
echo "########## A. mount_writable + /private/var (init.c 595-680) ##########"
sed -n '595,680p' /root/star26/hackios-xnu-userland/userland/src/boot/init.c
echo "########## B. init_mount.inc full ##########"
cat /root/star26/hackios-xnu-userland/userland/src/boot/init_mount.inc
echo "########## C. mount_writable definition search ##########"
grep -n "mount_writable\|ANNFS\|ufs_darwin_var\|/private/var" /root/star26/hackios-xnu-userland/userland/src/boot/init.c | head -40
echo "########## D. RAMFS volume size & mount path in kernel ##########"
grep -rn "RAMFS_VOLUME_PAGES\|ramfs_mount\|/private/var\|MOUNT_POINT" /root/star26/star-native/bsd/vm/vm_unix.c /root/star26/star-native/bsd/miscfs/ 2>/dev/null | head -40
