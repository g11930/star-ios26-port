#!/bin/bash
set -u
echo "== where is procfs? =="
find /root/star26/star-native/bsd -maxdepth 3 -type d -name "procfs*" 2>/dev/null | head -5
find /root/star26/star-native/bsd -maxdepth 4 -name "procfs*" 2>/dev/null | head -10
echo
echo "== environ / procargs occurrences anywhere in bsd =="
grep -rn "Penviron\|proc_environ\|\"environ\"" /root/star26/star-native/bsd/ 2>/dev/null | head -10
echo
echo "== KERN_PROCARGS2 support =="
grep -rn "KERN_PROCARGS2" /root/star26/star-native/bsd/ 2>/dev/null | head -8
