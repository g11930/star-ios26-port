#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. fki_is_skipped_func_name ==="
grep -rn 'fki_is_skipped_func_name\|fki_' $T/osfmk/kern/*.c $T/osfmk/kern/*.h 2>/dev/null | grep -v BUILD | head -30
echo
echo "=== B. startup.h 236-270 (STARTUP/__STARTUP_ARG 宏) ==="
sec $T/osfmk/kern/startup.h 230 275
echo
echo "=== C. startup.h 140-200 ==="
sec $T/osfmk/kern/startup.h 140 200
echo
echo "=== D. kern_exec.c ip_csflags 初始化 ==="
grep -rn 'ip_csflags' $T/bsd/kern/kern_exec.c | head -40
echo
echo "=== E. mach_loader.c 1325-1345 ==="
sec $T/bsd/kern/mach_loader.c 1325 1345
echo "=== DONE ==="
