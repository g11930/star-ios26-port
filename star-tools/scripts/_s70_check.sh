#!/bin/bash
F=/mnt/c/ios26/s70-log1.bin
echo "=== size / probe ==="
wc -c "$F"
grep -ac "StarMsgProbe" "$F"
echo "=== passes ==="
grep -aoE "pass [0-9]+" "$F" | sort -u
echo "=== imq / recv_name / queued-ids ==="
grep -aoE "TURNSTILE-PORT type=[A-Za-z0-9_]+ imq=[0-9]+/[0-9]+|recv_name=0x[0-9a-f]+|queued-ids=[0-9,]+" "$F" | sort | uniq -c
echo "=== launchd receive rcv name（对比用） ==="
grep -aoE "mach_msg opt=0x[0-9a-f]+ rcv=[0-9a-f]+" "$F" | sort | uniq -c
echo "=== 完整 backboardd turnstile 片段 ==="
grep -a "TURNSTILE-PORT" "$F" | head -1 | cut -c1-680
