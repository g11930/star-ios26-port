#!/bin/bash
F=/mnt/c/ios26/s65-log1.bin
echo "=== 1. xpcproxy 加载与退出时序（on-demand spawn 尝试） ==="
grep -anE "EXECDBG: loading.*xpcproxy|P28EXIT: pid [0-9]+ xpcproxy|xpcproxy xstat" "$F" | head -40
echo
echo "=== 2. launchd 所有 Doing boot task / spawn 决策（最后 30 条） ==="
grep -a "com.apple.xpc.launchd" "$F" | grep -E "Doing boot task|spawn|Spawning|ondemand|xpcproxy|service" | tail -30
echo
echo "=== 3. 所有 EXECDBG loading（本轮真正 exec 的二进制） ==="
grep -ao "EXECDBG: loading [^ ]*" "$F" | sed 's#.*/##' | sort | uniq -c | sort -rn
echo
echo "=== 4. P28EXIT 汇总（谁退出、退出码） ==="
grep -aoE "P28EXIT: pid [0-9]+ [^ ]+ xstat [0-9]+" "$F" | sed -E 's/pid [0-9]+ //' | sort | uniq -c | sort -rn | head -20
