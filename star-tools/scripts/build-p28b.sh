#!/bin/bash
# Force the two probe files through the compiler again and prove the strings land in both
# the object and the linked kernel.  (Plain make said "nothing to do": the objects were
# already newer than the sources, but they were built from the pre-probe text.)
set -e
B=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
rm -f "$B/osfmk/RELEASE/sleh.o" "$B/osfmk/RELEASE/sleh.o.json" "$B/osfmk/RELEASE/sleh.d"
rm -f "$B/bsd/RELEASE/kern_exit.o" "$B/bsd/RELEASE/kern_exit.o.json" "$B/bsd/RELEASE/kern_exit.d"
touch /root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
touch /root/star26/kbuild/xnu-12377.121.6/bsd/kern/kern_exit.c
cd /root/star26/kbuild/xnu-12377.121.6
bash /root/build-p28.sh > /root/star26/p28-build.log 2>&1 || {
	echo "BUILD FAILED"
	grep -n "error:" /root/star26/p28-build.log | head -20
	exit 1
}
echo "--- objects ---"
grep -aq P28FAULT "$B/osfmk/RELEASE/sleh.o" && echo "sleh.o HAS probe" || echo "sleh.o NO probe"
grep -aq P28EXIT "$B/bsd/RELEASE/kern_exit.o" && echo "kern_exit.o HAS probe" || echo "kern_exit.o NO probe"
echo "--- kernel ---"
grep -aq P28FAULT "$B/mach.release.bcm2837" && echo "kernel HAS P28FAULT" || echo "kernel NO P28FAULT"
grep -aq P28EXIT "$B/mach.release.bcm2837" && echo "kernel HAS P28EXIT" || echo "kernel NO P28EXIT"
ls -la --time-style=full-iso "$B/mach.release.bcm2837"
md5sum "$B/mach.release.bcm2837"
