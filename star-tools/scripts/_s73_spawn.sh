#!/bin/bash
L=/mnt/c/ios26/s73-log.bin
echo "===== 1. who spawned SpringBoard / backboardd ====="
strings -n 6 "$L" | grep -i -E 'backboardd|SpringBoard' | grep -i -E 'spawn|launch|exec|loading|SPWN|EXIT' | head -20
echo
echo "===== 2. SPWNVAL / SPWNRET / P2BEXIT sequence (first 30) ====="
strings -n 6 "$L" | grep -E 'STARX (SPWNVAL|SPWNRET)|P2BEXIT|EXECDBG' | head -30
echo
echo "===== 3. rc.launchd head ====="
head -50 /root/star26/hackios-xnu-userland/userland/rc.launchd 2>/dev/null
echo
echo "===== 4. job count in our cache build tree ====="
ls /root/star26/hackios-xnu-userland/userland/root/LaunchDaemons/ 2>/dev/null | head -10
find /root/star26/hackios-xnu-userland/userland -maxdepth 3 -name 'LaunchDaemons' -type d 2>/dev/null | head -5
