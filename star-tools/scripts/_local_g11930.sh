#!/bin/bash
G=/root/g11930-ref/xnu/files/bsd/dev/redwood_goodix.c
echo "=== local g11930 goodix: $(wc -l < "$G") lines ==="
grep -nE "SE_PHYS|PIN_AVDD|GCC_QUP1_SE5_CBCR|VOTE_QUP1_SE5|star|lahaina|sm8350|PIN_MISO|CMD_DB_PHYS" "$G" | head -30
echo
echo "=== local g11930 git log/status ==="
cd /root/g11930-ref
git log --oneline -5 2>/dev/null
git status --short 2>/dev/null | head -20
