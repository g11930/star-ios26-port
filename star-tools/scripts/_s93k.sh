#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. proc_csflags_update 实现 ==="
grep -n 'proc_csflags_update\|proc_csflags_set(\|proc_csflags_clear(' $T/bsd/kern/kern_proc.c | head -20
sec $T/bsd/kern/kern_proc.c 2200 2270
echo
echo "=== B. kern_exec.c 2273 所在函数（往前找函数头） ==="
awk 'NR>=2100 && NR<=2280 && /^[a-zA-Z_].*\(|^static |^void|^int|^errno_t/ {print NR": "$0}' $T/bsd/kern/kern_exec.c | tail -20
echo "--- 2150-2280 头尾 ---"
sec $T/bsd/kern/kern_exec.c 2150 2200
echo
echo "=== C. imgp->ip_csflags 初始化 / exec_copyin / imgp 清零 ==="
grep -rn 'ip_csflags' $T/bsd/kern/kern_exec.c $T/bsd/sys/imgact.h $T/bsd/sys/imgact_internal.h 2>/dev/null | head -30
echo
echo "=== D. proc_csflags_update 定义 ==="
grep -rn 'proc_csflags_update' $T/bsd --include=*.c --include=*.h 2>/dev/null | grep -v BUILD | head -20
echo
echo "=== E. kern_exec.c 8990-9010 ==="
sec $T/bsd/kern/kern_exec.c 8990 9010
echo "=== DONE ==="
