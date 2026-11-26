#!/bin/bash
L=/mnt/d/ios26/now-075648.bin
echo "===== PANIC 上下文 ====="
grep -a -i -n -B1 -A1 "PANIC" "$L" | head -20
echo
echo "===== SMMU fault 真故障（space_faulted / translation refused / fault 关键词）====="
grep -a -i -E "refused translation|space faulted|translation fault|SMMU.*fault|FAULT.*SMMU" "$L" | head -10
echo
echo "===== fault 行 ====="
grep -a -i "fault" "$L" | head -8
