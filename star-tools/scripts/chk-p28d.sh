#!/bin/bash
B=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
echo "--- sleh.o ---"
ls -la --time-style=full-iso "$B/osfmk/RELEASE/sleh.o"
grep -aq P28FAULT "$B/osfmk/RELEASE/sleh.o" && echo "sleh.o HAS probe" || echo "sleh.o NO probe"
echo "--- kern_exit.o ---"
ls -la --time-style=full-iso "$B/bsd/RELEASE/kern_exit.o"
grep -aq P28EXIT "$B/bsd/RELEASE/kern_exit.o" && echo "kern_exit.o HAS probe" || echo "kern_exit.o NO probe"
echo "--- source ---"
ls -la --time-style=full-iso /root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c /root/star26/kbuild/xnu-12377.121.6/bsd/kern/kern_exit.c
echo "--- linked archive / kernel ---"
ls -la --time-style=full-iso "$B/mach.release.bcm2837" "$B/mach.release.bcm2837.unstripped" 2>&1
