#!/bin/bash
echo "=== annibale drivers in kbuild ==="
ls -la /root/star26/kbuild/xnu-12377.121.6/bsd/dev/annibale/ 2>/dev/null | head -25
echo
echo "=== same dir in hackios-xnu-kernel ==="
ls /root/star26/hackios-xnu-kernel/xnu/files/bsd/dev/annibale/ 2>/dev/null | head -25
echo
echo "=== what does build-star-native.sh compile? ==="
grep -n 'cd \|SRC=\|xnu-build\|make ' /mnt/d/桌面/star26-deps/scripts/build-star-native.sh 2>/dev/null | head -20
echo
echo "=== adreno boot gate in the real driver ==="
grep -n 'boot_argn' /root/star26/kbuild/xnu-12377.121.6/bsd/dev/annibale/annibale_gpu_dispatch.c 2>/dev/null | head -10
