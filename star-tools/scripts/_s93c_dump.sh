#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== 1. cs_blobs.h 位定义 ==="
grep -n '#define CS_' $T/osfmk/kern/cs_blobs.h | head -80
echo

echo "=== 2. ip_csflags 赋值点 ==="
grep -rn 'ip_csflags *=' $T/bsd/kern/*.c $T/bsd/kern/*.h 2>/dev/null | head -40
echo

echo "=== 3. csproc platform binary 函数定义 ==="
grep -rn 'csproc_get_platform_binary\|csproc_set_platform_binary\|csproc_clear_platform_binary\|csproc_get_platform_path' $T --include=*.c --include=*.h 2>/dev/null | grep -v 'BUILD/obj' | head -40
echo

echo "=== 4. proc_csflags_set / proc_csflags_clear 全部调用点 ==="
grep -rn 'proc_csflags_set\|proc_csflags_clear' $T/bsd --include=*.c 2>/dev/null | head -60
echo

echo "=== 5. miniamfi.c (libkern) ==="
ls -l $T/libkern/amfi/ 2>&1
echo

echo "=== 6. kern_proc.c CS_OPS_IDENTITY 段 (4070-4150) ==="
sec $T/bsd/kern/kern_proc.c 4070 4150
echo "=== DONE ==="
