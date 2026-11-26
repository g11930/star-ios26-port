#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_exec.c
F=/mnt/c/ios26/s64-logdump.bin
echo "=== spawn_no_exec set point (5015-5060) ==="
sed -n '5015,5060p' "$K"
echo
echo "=== persona id 199/200/100 meaning ==="
grep -nE "\b(199|200|100)\b" /root/star26/star-native/bsd/sys/persona.h | head
echo
echo "=== FB: any run with panel rows drawn > 0 ? ==="
strings -a "$F" | grep "MiniIOMobileFramebuffer" | grep -v "no row changed" | head -20
echo
echo "=== FB: unique summary lines (dedup) ==="
strings -a "$F" | grep "panel rows drawn" | sed 's/^.*: //' | sort -u | head -20
echo
echo "=== backlight final states (dedup) ==="
strings -a "$F" | grep "to the backlight" | sed 's/^.*to the backlight: //' | sort -u | head
echo
echo "=== SpringBoard beats (last 6) ==="
strings -a "$F" | grep "SpringBoard beat" | tail -6
echo
echo "=== process list tail ==="
strings -a "$F" | sed -n '/-- processes --/,$p' | head -70
