#!/bin/bash
# s92: system root comes from ufs_darwin (the darwin partition on the phone, UFS).
# backboardd binary lives there. Question: does it carry an embedded signature?
# We can't read UFS from WSL easily; but the ORIGINAL iOS26 rootfs extraction on macOS side
# is what got copied to the darwin partition. Find that tree.
echo "===MACOS-EXTRACT-LOCATION==="
# per build.sh: IOS=../ios26 (rootfs/); the phone's darwin partition was written from it
ls /root/star26/hackios-xnu-userland/ios26/
find /root -maxdepth 4 -type d -name 'rootfs' 2>/dev/null | head -3
