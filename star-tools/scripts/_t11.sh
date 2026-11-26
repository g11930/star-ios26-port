#!/bin/bash
echo "=== STAR doc touch section ==="
sed -n '5,20p;80,95p' /root/g11930-ref/docs/STAR.zh-CN.md
echo "=== clocks_on trace in ref boot logs? ==="
grep -rn 'QUP1_S_AHB\|S_AHB' /root/g11930-ref --include=*.c --include=*.md | head -8