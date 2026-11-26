#!/bin/bash
set +e
F=/tmp/logdump_cur.bin
echo "=== 1. xpcproxy 结局/exit ==="
strings -a "$F" | grep -iE "xpcproxy|xstat|EXIT" | grep -iE "xstat|P28EXIT|exit" | head -40
echo "=== 2. P28EXIT 全表（哪些进程退出、码多少）==="
strings -a "$F" | grep -a "P28EXIT" | sort | uniq -c | head -40
echo "=== 3. persona 与 spawn 的时序关联（连续行）==="
strings -a "$F" | grep -nE "persona with type|xpcproxy cputype|Successfully spawned|speculative|service state: running" | head -80
echo "=== 4. bootstrap 端口相关 ==="
strings -a "$F" | grep -iE "bootstrap|mach port for persistent|bootstrap_port|lookup.*failed|kr=15|KERN_INVALID_NAME" | head -30
