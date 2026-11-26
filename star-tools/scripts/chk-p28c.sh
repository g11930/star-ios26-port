#!/bin/bash
B=/root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837
echo "--- osfmk obj dir ---"
ls -la --time-style=full-iso "$B/osfmk/arm64/RELEASE/" 2>&1 | head -20
echo "--- any sleh object ---"
find /root/star26/kbuild/xnu-12377.121.6/BUILD -name "sleh.*" 2>/dev/null | head
echo "--- kernel_exit object ---"
find /root/star26/kbuild/xnu-12377.121.6/BUILD -name "kern_exit.*" 2>/dev/null | head
echo "--- log size / last build ---"
ls -la --time-style=full-iso /root/star26/p28-build.log
grep -c . /root/star26/p28-build.log
