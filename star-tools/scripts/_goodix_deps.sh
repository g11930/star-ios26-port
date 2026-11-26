#!/bin/bash
F=/root/g11930-ref/xnu/files/bsd/dev/redwood_goodix.c
echo "=== external redwood_ symbols it calls ==="
grep -o '\bredwood_[a-z0-9_]*' $F | sort -u | head -30
echo "=== includes ==="
grep -n '^#include' $F | head -25
echo "=== how it posts touches ==="
grep -n 'redwood_touch_post\|redwood_cpufreq_touch\|printf(' $F | head -10
</