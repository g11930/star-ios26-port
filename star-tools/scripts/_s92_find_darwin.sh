#!/bin/bash
# s92: the darwin partition holds the big system; ramdisk is just init. Check darwin partition image.
# Where is the darwin container image built?
ls /root/star26-deps/gpt/ 2>/dev/null | head
echo "===WINDOWS-SIDE-DARWIN==="
ls /mnt/d/桌面/star26-deps/gpt/ 2>/dev/null | head
find /mnt/d/桌面/star26-deps -maxdepth 2 -name '*darwin*' 2>/dev/null | head
echo "===S91-CMDLINE==="
cat /root/star26/s91/parts/cmdline
