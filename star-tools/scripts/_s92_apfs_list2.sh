#!/bin/bash
# s92: list root of system image (ramdisk = /dev/md0) and check backboardd CodeSignature
cd /root/star26/hackios-xnu-userland/tools/apfs || exit 1
python3 apfs.py 2>&1 | head -15 || true
echo "===HELP==="
python3 apfs.py --help 2>&1 | head -20 || python3 apfs.py -h 2>&1 | head -20
