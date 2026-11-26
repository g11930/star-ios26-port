#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

sec $T/bsd/kern/kern_cs.c 130 320
echo
echo "=== true ==="
awk 'NR>=360 && NR<=370 {printf "%6d  %s\n", NR, $0}' $T/bsd/kern/kern_cs.c
echo "=== DONE ==="
