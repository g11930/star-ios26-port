#!/bin/bash
L=/mnt/c/ios26/s73-log.bin
echo "===== 1. our registered job count (from boot log listing) ====="
strings -n 6 "$L" | grep -o '/annibale/LaunchDaemons/[a-zA-Z0-9._-]*\.plist' | sort -u | wc -l
echo
echo "===== 2. find dyld shared cache locally ====="
find /root/star26 -maxdepth 4 -iname 'dyld_shared_cache*' 2>/dev/null | head -5
find /root/star26 -maxdepth 4 -iname 'launchd.ios' -o -maxdepth 4 -iname 'launchd' -type f 2>/dev/null | head -5
echo
echo "===== 3. iOS rootfs present? ====="
ls -d /root/star26/hackios-xnu-userland/ios26 /root/star26/ios26 /root/star26/rootfs 2>/dev/null
find /root/star26 -maxdepth 3 -iname 'system26*' -o -maxdepth 3 -iname 'system.apfs' 2>/dev/null | head -5
