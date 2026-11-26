#!/bin/bash
F=/mnt/c/ios26/s65-log1.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== TURNSTILE-PORT / turnstile-lookup（本轮核心） ==="
grep -aoE "TURNSTILE-PORT type=[A-Za-z0-9_]+|turnstile-lookup kr=-?[0-9]+" "$F" | sort | uniq -c | sort -rn
echo
echo "=== 完整 WAIT 行序列（含 turnstile 结果） ==="
grep -aoE "StarMsgProbe:   WAIT pc=[^S]*" "$F" | head -30
echo
echo "=== TURNSTILE-PORT 附近的 peer 行 ==="
grep -a "TURNSTILE-PORT" "$F" | head -20
echo
echo "=== pass 计数 ==="
grep -aoE "pass [0-9]+" "$F" | sort -u
