#!/bin/bash
# s60: everything after launchd_cache_loader's boot task
N=$(grep -n 'launchd_cache_loader) <Notice>: Doing boot task' /tmp/s60.txt | head -1 | cut -d: -f1)
echo "cache_loader at line $N"
awk -v n="$N" 'NR>=n' /tmp/s60.txt | grep -vE 'logdtrace|say [0-9]+ trace' | head -70
