#!/bin/bash
F=/mnt/c/ios26/s65-log1.bin
echo "=== launchd 最近活动（时间戳最后 15 行） ==="
grep -a "com.apple.xpc.launchd" "$F" | tail -15
echo
echo "=== backboardd 最后活动 ==="
grep -aiE "backboardd" "$F" | grep -viE "library insertion|EXECDBG|cmdline|boot-args" | tail -20
echo
echo "=== SpringBoard beat 心跳（是否在跑） ==="
grep -aoE "SpringBoard beat [0-9]+ self=[0-9]+ms" "$F" | tail -10
echo
echo "=== 是否有 service 名字线索（check-in / service name） ==="
grep -aiE "check.?in|com\.apple\.[a-z.]+service|bootstrap.*service|service.*bootstrap|mach service" "$F" | grep -viE "cmdline|boot-args|EXECDBG" | tail -20
echo
echo "=== launchd 'no mach port' / bootstrap 相关（本轮） ==="
grep -aiE "no mach port|bootstrap|could not|failed to|error" "$F" | grep -a "launchd" | tail -20
