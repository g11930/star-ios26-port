#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. startup.h 子系统枚举定义 ==="
grep -n 'STARTUP_SUB_\|CODESIGNING' $T/osfmk/kern/startup.h | head -60
echo
echo "=== B. startup.c 枚举执行逻辑 ==="
ls -l $T/osfmk/kern/startup.c 2>&1
grep -n 'STARTUP_SUB_\|__init_entry_set\|init_entry_set\|subsystem' $T/osfmk/kern/startup.c 2>/dev/null | head -60
echo
echo "=== C. 全树搜 __init_entry_set 引用 ==="
grep -rn '__init_entry_set' $T --include=*.c --include=*.h --include=*.s 2>/dev/null | grep -v 'BUILD/obj' | head -30
echo
echo "=== D. STARTUP 宏定义 ==="
grep -n 'define STARTUP\b\|define STARTUP(\|STARTUP_RANK_FIRST' $T/osfmk/kern/startup.h | head -20
echo "=== DONE ==="
