#!/bin/bash
# Apply the SoC-identity patch to both trees, then rebuild the 12377 RELEASE kernel.
# Host side only: nothing is flashed, no device command is issued.
python3 /mnt/d/桌面/star26-deps/scripts/patch-soc-identity.py || exit 1
bash /mnt/d/桌面/star26-deps/scripts/build-k90-tree.sh > /root/star26/kbuild/build-p40.log 2>&1
rc=$?
echo "BUILD_EXIT=$rc"
tail -12 /root/star26/kbuild/build-p40.log
K=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/mach.release.bcm2837
if [ -f "$K" ]; then
	ls -l "$K"
	md5sum "$K"
	sha256sum "$K"
fi
exit $rc
