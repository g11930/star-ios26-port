#!/bin/bash
F=/mnt/c/ios26/s69-log1.bin
echo "=== StarMsgProbe 计数 ==="
grep -ac "StarMsgProbe" "$F"
echo "=== pass ==="
grep -aoE "pass [0-9]+" "$F" | sort -u
echo "=== turnstile 相关行 ==="
grep -a "turnstile\|TURNSTILE\|imq=\|queued-ids" "$F" | head -20
echo "=== 最后 20 行 ==="
tail -20 "$F"
echo "=== 关键计数 ==="
for k in logd backboardd SpringBoard "Early boot complete"; do echo -n "$k="; grep -ac "$k" "$F"; done
