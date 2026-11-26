#!/bin/bash
# P28: rebuild the RELEASE kernel with the two diagnostic probes and prove the probes are
# in the binary before anything gets packed.
set -e
cd /root/star26/kbuild/xnu-12377.121.6
bash /root/build-p28.sh > /root/star26/p28-build.log 2>&1 || {
	echo "BUILD FAILED"
	grep -n "error:" /root/star26/p28-build.log | head -20
	exit 1
}
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
echo "--- built ---"
ls -la --time-style=full-iso "$K"
md5sum "$K"
echo "--- probes in the binary ---"
if grep -aq "P28FAULT" "$K"; then echo "P28FAULT yes"; else echo "P28FAULT NO"; fi
if grep -aq "P28EXIT" "$K"; then echo "P28EXIT yes"; else echo "P28EXIT NO"; fi
echo "--- compiled objects ---"
grep -n "CC  " /root/star26/p28-build.log | tail -8
