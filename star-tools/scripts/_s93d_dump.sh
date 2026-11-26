#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }
gr() { echo "=== $1 ==="; shift; grep -rn "$@" $T --include=*.c --include=*.h 2>/dev/null | grep -v 'BUILD/obj' | head -30; echo; }

gr "csproc_set_platform_binary 定义/调用" 'csproc_set_platform_binary'
gr "csproc_platform_binary 字段" 'csproc_platform_binary\|p_csplatform\|cs_platform_binary'
gr "codesign.h csproc 声明" 'csproc_.*platform' $T/bsd/sys/codesign.h

sec $T/bsd/kern/kern_cs.c 900 1010
sec $T/bsd/kern/kern_exec.c 9197 9290

echo "=== Accelerator 属性改动痕迹 ==="
grep -rn 'kAcceleratorPluginNameKey\|kAcceleratorPluginClassNameKey\|AcceleratorPlugin' $T --include=*.c --include=*.cpp --include=*.h 2>/dev/null | grep -v 'BUILD/obj' | head -30
echo
echo "=== star 私有 IOAccelerator / metal stub 文件 ==="
find $T -iname '*ccelerator*' -o -iname '*annibale*' -o -iname '*star*metal*' 2>/dev/null | grep -v 'BUILD/obj' | head -30
echo "=== DONE ==="
