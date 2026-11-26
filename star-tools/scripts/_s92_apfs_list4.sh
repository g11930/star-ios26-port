#!/bin/bash
cd /root/star26/hackios-xnu-userland/tools/apfs || exit 1
R=/root/star26/s91/parts/ramdisk
echo "===sbin==="
python3 apfs.py ls "$R" /sbin 2>&1 | grep -i 'backboard\|launchd' | head
echo "===sbin-all==="
python3 apfs.py ls "$R" /sbin 2>&1 | head -30
echo "===Applications==="
python3 apfs.py ls "$R" /Applications 2>&1 | head -10
