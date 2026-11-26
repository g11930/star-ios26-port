#!/bin/bash
F=/mnt/c/ios26/s69-log2.bin
echo "=== probe count ==="
grep -ac "StarMsgProbe" "$F"
echo "=== passes ==="
grep -aoE "pass [0-9]+" "$F" | sort -u
echo "=== imq/queued-ids ==="
grep -aoE "TURNSTILE-PORT type=[A-Za-z0-9_]+ imq=[0-9]+/[0-9]+|queued-ids=[0-9,]+" "$F" | sort | uniq -c
echo "=== turnstile 附近 ==="
grep -a "TURNSTILE-PORT" "$F" | head -2 | cut -c1-500
