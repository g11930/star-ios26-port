#!/bin/bash
F=/mnt/c/ios26/s64-fresh2.bin
echo "=== 所有 wait / trap 行（完整） ==="
grep -aE "say .*wait [0-9]+:|say .*trap|say .*msgprobe|waitq-diag|lookup|special reply|WQ" "$F" | head -80
echo
echo "=== SPWNRET 全部（解码 spawn 结果） ==="
grep -ao "SPWNRET a=0x[0-9a-f]* b=0x[0-9a-f]*" "$F" | sort | uniq -c | sort -rn
echo
echo "=== backboardd / SpringBoard 相关全部 ==="
grep -aE "backboardd|SpringBoard" "$F" | grep -aiE "wait|trap|port|reply|service|lookup|blocked|error|fail" | head -50
