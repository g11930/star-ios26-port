#!/bin/bash
F=/mnt/c/ios26/s66-log-early.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== starcat 是否已启动/等待 ==="
grep -a "starcat" "$F" | head -20
echo
echo "=== 基线确认：TURNSTILE-PORT / backboardd ==="
grep -aoE "TURNSTILE-PORT type=[A-Za-z0-9_]+|peer=launchd\([0-9]+\)|peer=logd\([0-9]+\)" "$F" | sort | uniq -c
echo
echo "=== logd 崩溃次数（xstat 5） ==="
grep -aoE "P28EXIT: pid [0-9]+ logd xstat [0-9]+" "$F" | sort | uniq -c | head
echo "logd xstat5 total="; grep -ac "logd xstat 5" "$F"
echo
echo "=== 进度/启动标记 ==="
for k in "Early boot complete" "SpringBoard" "backboardd" "Early boot"; do echo -n "$k="; grep -ac "$k" "$F"; done
