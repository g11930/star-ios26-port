#!/bin/bash
set +e
K=/root/star26/star-native/bsd/kern/kern_exec.c
echo "=== posix_spawn func start ==="
grep -n "^posix_spawn(" "$K"
echo "=== bad: labels 5700-5900 ==="
awk 'NR>=5700 && NR<=5900 && /bad:/{print NR": "$0}' "$K"
echo "=== return/error 5830-5910 ==="
awk 'NR>=5830 && NR<=5910 && (/return/ || /bad:/){print NR": "$0}' "$K"
echo "=== copyinstr usage ==="
grep -n "copyinstr" "$K" | head -10
echo "=== struct posix_spawn_args fields (path type) ==="
grep -rn "struct posix_spawn_args" /root/star26/star-native/bsd/sys/*.h | head -5
