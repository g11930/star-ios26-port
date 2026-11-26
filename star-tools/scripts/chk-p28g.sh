#!/bin/bash
echo "--- object json (the actual compile command) ---"
head -c 1200 /root/star26/kbuild/xnu-12377.121.6/BUILD/obj/RELEASE_ARM64_BCM2837/osfmk/RELEASE/sleh.o.json
echo
echo "--- source now ---"
md5sum /root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
grep -c P28FAULT /root/star26/kbuild/xnu-12377.121.6/osfmk/arm64/sleh.c
