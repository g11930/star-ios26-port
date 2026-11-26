#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_minimac.c
echo "=== IOLog count in file ==="
grep -c 'IOLog' "$K"
echo "=== current hook (60-90) ==="
sed -n '60,90p' "$K"
echo "=== sys/systm.h included? (IOLog home) ==="
grep -n '#include <sys/systm.h>' "$K"
echo "=== other kern files using IOLog ==="
grep -rl 'IOLog' /root/star26/star-native/bsd/kern/*.c 2>/dev/null | head -3
echo "=== current md5 ==="
md5sum "$K" "$K".s95-pre-step2.bak
