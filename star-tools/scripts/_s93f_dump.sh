#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== CS_ALLOWED_MACHO 定义 ==="
sed -n '55,60p' $T/osfmk/kern/cs_blobs.h
echo
sec $T/bsd/kern/mach_loader.c 3821 3930
echo
echo "=== ubc_subr.c 5650-5720 (mac_vnode_check_signature 调用处) ==="
sec $T/bsd/kern/ubc_subr.c 5640 5720
echo
echo "=== kern_exec.c 9080-9150 ==="
sec $T/bsd/kern/kern_exec.c 9080 9150
echo "=== DONE ==="
