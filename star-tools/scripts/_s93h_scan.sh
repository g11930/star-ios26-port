#!/bin/bash
T=/root/star26/star-native
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. ubc_subr.c:4864 所在函数（往上找签名） ==="
awk 'NR>=4760 && NR<=4870 {printf "%6d  %s\n", NR, $0}' $T/bsd/kern/ubc_subr.c
echo
echo "=== B. 全 star26 目录树 24h 内修改的文件（排除 BUILD/obj） ==="
find /root/star26 -newermt '2026-11-16 12:00' -type f 2>/dev/null | grep -v 'BUILD/obj' | grep -v '/\.git/' | head -60
echo
echo "=== C. accelerator 关键词全盘搜索 ==="
grep -rln 'AcceleratorPlugin\|IOAcceleratorES\|kAccelerator' /root/star26 /root/star26-deps 2>/dev/null | head -30
echo
echo "=== D. .workbuddy/wsl 与 payload 脚本 ==="
ls -lt /root/star26-deps/scripts/ 2>/dev/null | head -30
echo
echo "=== E. 找所有含 sgx / IOAccelerator 的文本 ==="
grep -rln 'sgx\|IOAccelerator' /root/star26-deps 2>/dev/null | head -20
echo "=== DONE ==="
