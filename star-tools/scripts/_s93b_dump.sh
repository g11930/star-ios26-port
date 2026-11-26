#!/bin/bash
# S93b: dump 关键代码块
T=/root/star26/star-native
show() { echo "########## $1 : $2-$3 ##########"; sed -n "${2},${3}p" "$1" | cat -n | awk -v s=$2 '{printf "%6d  %s\n", s+$1-1, substr($0, index($0,$2)==0?1:length($1)+7)}'; echo; }

sec() { f=$1; a=$2; b=$3; echo "########## $f : $a-$b ##########"; awk -v a=$a -v b=$b 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$f"; echo; }

sec $T/bsd/kern/kern_minimac.c 1 90
sec $T/bsd/kern/kern_proc.c 3750 3810
sec $T/bsd/kern/kern_proc.c 4150 4200
sec $T/bsd/kern/ubc_subr.c 4860 4910
sec $T/bsd/kern/ubc_subr.c 4930 4970
sec $T/bsd/kern/kern_exec.c 9150 9200
sec $T/bsd/kern/kern_exec.c 2255 2295
echo "=== DONE ==="
