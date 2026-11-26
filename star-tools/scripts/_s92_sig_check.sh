#!/bin/bash
# s92: decisive - does s91 kernel have CSIDENT blobs at all?
# The chain: exec attaches cs blob from the binary (embedded signature).
# Question 1: are our ramdisk/system binaries even signed (ad hoc)? Check ramdisk contents.
echo "===RAMDISK-SIGNATURE==="
ls -la /root/star26/s91/parts/ramdisk 2>/dev/null
file /root/star26/s91/parts/ramdisk
echo "===HOW-RAMDISK-BUILT==="
ls /root/star26-deps 2>/dev/null | head
# find the ramdisk assembly script
grep -rln 'codesign\|ldid\|ad hoc\|CODESIGN' /root/star26/star-native/../hackios-xnu-userland/ 2>/dev/null | head -10
