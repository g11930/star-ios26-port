#!/bin/bash
LOG=/root/star26/p28-build.log
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
SRC1=/root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
SRC2=/root/star26/kbuild/xnu-12377.121.6/bsd/kern/kern_exit.c
O1=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/arm64/RELEASE/sleh.cpo
O2=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/bsd/RELEASE/kern_exit.cpo
echo "now: $(date)"
echo "--- source mtimes ---"
ls -la --time-style=full-iso "$SRC1" "$SRC2"
echo "--- object mtimes ---"
ls -la --time-style=full-iso "$O1" "$O2" 2>&1
echo "--- compile lines in log ---"
grep -c "CC" "$LOG"
grep -n "sleh\|kern_exit" "$LOG" | head
echo "--- symlink check ---"
readlink -f "$SRC1"
