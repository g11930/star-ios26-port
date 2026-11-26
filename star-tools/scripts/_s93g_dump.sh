#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

sec $T/bsd/kern/mach_loader.c 3930 4050

echo "=== result->csflags 全部赋值点 ==="
grep -rn 'result->csflags\|->csflags *|=' $T/bsd/kern/mach_loader.c | head -40
echo
echo "=== accelerator 改动搜索（宽泛） ==="
grep -rn 'AcceleratorPlugin\|kAcceleratorPlugin\|IOAccelerator' $T/iokit $T/osfmk $T/libkern --include=*.cpp --include=*.c --include=*.h 2>/dev/null | grep -v 'BUILD/obj' | head -40
echo
echo "=== IOAcceleratorES / sgx 相关 ==="
find $T -iname '*IOAccelerator*' -o -iname '*sgx*' -o -iname '*metal*' 2>/dev/null | grep -v 'BUILD/obj' | head -30
echo
echo "=== AnnibaleGPU.cpp 中 setProperty / Accelerator 关键字 ==="
grep -n 'setProperty\|Accelerator\|metal\|Metal' $T/iokit/Kernel/AnnibaleGPU.cpp | head -60
echo
echo "=== 加载器镜像/载荷是否比源码树新 ==="
ls -l $T/bsd/kern/mach_loader.c $T/iokit/Kernel/AnnibaleGPU.cpp
ls -lt /root/star26/ 2>/dev/null | head
echo
echo "=== 找 star-staged 相关产物 ==="
ls -lt /root/star26-deps/ 2>/dev/null | head -20
echo "=== DONE ==="
