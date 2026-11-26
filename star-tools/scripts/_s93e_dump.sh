#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== mach_loader.c 头部 star_cs 补丁区域 ==="
grep -n 'star_cs_probe\|star_cs_keep_valid\|star_cs_bootargs\|CS_INITPAGE\|STARTUP(CODESIGNING' $T/bsd/kern/mach_loader.c
echo
echo "=== mach_loader.c 初始页校验区 (1790-1890) ==="
sec $T/bsd/kern/mach_loader.c 1790 1890
echo
echo "=== mach_loader.c LC_CODE_SIGNATURE 门槛 ==="
grep -n 'LC_CODE_SIGNATURE\|pass == 1\|load_code_signature\|depth == 1' $T/bsd/kern/mach_loader.c | head -30
echo
echo "=== ubc_subr.c CS_VALID 置位点 ==="
grep -n 'CS_VALID' $T/bsd/kern/ubc_subr.c | head -30
echo
echo "=== amfi.c 全文 ==="
cat -n $T/libkern/amfi/amfi.c
echo
echo "=== miniamfi.c 全文 ==="
cat -n $T/libkern/amfi/miniamfi.c
echo "=== DONE ==="
