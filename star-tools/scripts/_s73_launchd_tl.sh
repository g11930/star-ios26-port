#!/bin/bash
# full launchd log timeline + last events, and check the built cache file
L=/mnt/c/ios26/s73-log.bin
echo "===== 1. count of launchd log lines ====="
strings -n 6 "$L" | grep -c 'com\.apple\.xpc\.launchd|'
echo
echo "===== 2. LAST 25 launchd lines (timeline tail) ====="
strings -n 6 "$L" | grep 'com\.apple\.xpc\.launchd|' | tail -25
echo
echo "===== 3. any (launchd_cache_loader) / cache lines ====="
strings -n 6 "$L" | grep -i 'cache' | grep -v 'flashcache' | head -15
echo
echo "===== 4. Accepted / domain / connection lines ====="
strings -n 6 "$L" | grep -i -E 'Accepted|domain|connection' | head -15
echo
echo "===== 5. built cache file in our userland tree ====="
ls -l /root/star26/hackios-xnu-userland/userland/root/xpc/launchd.plist 2>&1
ls -l /root/star26/hackios-xnu-userland/userland/root/LaunchDaemons/ 2>/dev/null | head -5
ls /root/star26/hackios-xnu-userland/userland/root/LaunchDaemons/*.plist 2>/dev/null | wc -l
