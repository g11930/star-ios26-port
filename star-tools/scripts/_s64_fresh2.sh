#!/bin/bash
F=/mnt/c/ios26/s64-fresh2.bin
echo "=== size ==="
wc -c "$F"
echo
echo "=== SPWN 打点计数 ==="
for t in SPWNVAL SPWNADOPT SPWNRET; do echo -n "$t="; grep -ao "$t" "$F" | wc -l; done
echo
echo "=== SPWN 打点内容 ==="
grep -aoE "SPWN(VAL|ADOPT|RET)[^
]*" "$F" | head -40
echo
echo "=== 启动关键标记 ==="
for k in "StarDisk: published" "Early boot complete" "launchd" "Cache sent" "xpcproxy" "WindowServer" "backboardd" "SpringBoard"; do echo -n "$k="; grep -aoF "$k" "$F" | wc -l; done
echo
echo "=== 内核 panic / abort ==="
grep -aiE "panic|data abort|Kernel data|debugger|SIGTRAP|trap" "$F" | head -20
echo
echo "=== 最后 60 行 ==="
tail -60 "$F"
