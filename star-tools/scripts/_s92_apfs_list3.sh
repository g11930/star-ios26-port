#!/bin/bash
cd /root/star26/hackios-xnu-userland/tools/apfs || exit 1
R=/root/star26/s91/parts/ramdisk
python3 apfs.py info "$R" 2>&1 | head -20
echo "===LS-ROOT==="
python3 apfs.py ls "$R" / 2>&1 | head -30
echo "===FIND-BACKBOARDD==="
python3 apfs.py ls "$R" /usr/sbin 2>&1 | grep -i backboard
python3 apfs.py ls "$R" /usr/libexec 2>&1 | grep -i backboard
