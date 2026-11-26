#!/bin/bash
F=/mnt/c/ios26/s64-fresh2.bin
echo "=== mach_msg2 / msg2_trap 出现处 ==="
grep -an "mach_msg2\|msg2_trap\|msg2_internal" "$F" | head -40
echo
echo "=== 'wait' 任意出现 ==="
grep -an "wait" "$F" | head -40
echo
echo "=== 'trap' 任意出现 ==="
grep -an "trap" "$F" | head -40
echo
echo "=== STARX 探针输出全部 tag 种类 ==="
grep -aoE "STARX [A-Z_]+" "$F" | sort | uniq -c | sort -rn | head -40
echo
echo "=== say N 的 N 分布（哪个进程在打点） ==="
grep -aoE "say [0-9]+" "$F" | sort | uniq -c | sort -rn | head -30
