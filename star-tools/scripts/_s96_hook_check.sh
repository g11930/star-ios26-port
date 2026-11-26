#!/bin/bash
K=/root/star26/star-native/bsd/kern/kern_minimac.c
OUT=/mnt/c/ios26/s96_hook_check.out
: > "$OUT"

echo "=== 1) hook function (48-70) ===" >> "$OUT"
sed -n '48,70p' "$K" >> "$OUT"

echo "" >> "$OUT"
echo "=== 2) includes (24-48) ===" >> "$OUT"
sed -n '24,48p' "$K" >> "$OUT"

echo "" >> "$OUT"
echo "=== 3) STARTUP / constructor / boot-arg patterns in this file ===" >> "$OUT"
grep -n 'STARTUP\|__startup_func\|constructor\|PE_parse_boot_argn\|minimac_policy_init' "$K" >> "$OUT"

echo "" >> "$OUT"
echo "=== 4) minimac_policy_init body (440-452) ===" >> "$OUT"
sed -n '440,452p' "$K" >> "$OUT"

echo "" >> "$OUT"
echo "=== 5) current source md5 + backups ===" >> "$OUT"
md5sum "$K" "$K".s92.bak 2>&1 >> "$OUT"

echo "" >> "$OUT"
echo "=== 6) CS_VALID constant value in headers ===" >> "$OUT"
grep -rn 'define CS_VALID' /root/star26/star-native/bsd/sys/codesign.h 2>/dev/null | head -3 >> "$OUT"

echo "" >> "$OUT"
echo "=== DONE ===" >> "$OUT"
echo "OK $(wc -c < "$OUT") bytes"
