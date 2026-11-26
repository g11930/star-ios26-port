#!/bin/bash
T=/root/star26/star-native
U=/root/star26/hackios-xnu-userland
sec() { echo "########## $1 : $2-$3 ##########"; awk -v a=$2 -v b=$3 'NR>=a && NR<=b {printf "%6d  %s\n", NR, $0}' "$1"; echo; }

echo "=== A. mac_proc_check_run_cs_invalid 在 minimac 的实现 ==="
grep -rn 'mac_proc_check_run_cs_invalid\|mpo_proc_check_run_cs_invalid\|check_run_cs_invalid' $T/bsd/kern/kern_minimac.c $T/security/mac_policy.h 2>/dev/null | head -20
echo
echo "=== B. minisandbox 的 mac policy 注册表 ==="
grep -n 'mpo_\|minimac_policy' $T/bsd/kern/kern_minimac.c | head -60
echo
echo "=== C. vm_fault.c 8930-8990 (cs_validate_page 调用点) ==="
sec $T/osfmk/vm/vm_fault.c 8920 8990
echo
echo "=== D. vm_fault.c 9090-9130 ==="
sec $T/osfmk/vm/vm_fault.c 9090 9130
echo "=== DONE ==="
