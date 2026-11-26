#!/bin/bash
K=/root/star26/warsaw-ref/userland/src/inject_sb26.c
echo "=== interpose table 1045-1075 ==="
sed -n '1045,1075p' "$K"
echo "=== xpc install / interpose references (tail) ==="
grep -n 'install_xpc\|sb26_xpc\|INTERPOSE\|interpose' "$K" | tail -12
echo "=== K90 build.sh sb26 dylib compile line ==="
grep -n -A2 -B2 'inject_sb26.c' /root/star26/warsaw-ref/userland/build.sh | head -20
echo "=== star build.sh sb26 dylib compile line ==="
grep -n -A2 -B2 'inject_sb26.c' /root/star26/hackios-xnu-userland/userland/build.sh | head -20
