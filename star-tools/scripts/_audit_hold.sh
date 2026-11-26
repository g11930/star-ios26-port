#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "===== hold() 实现 (200-225) ====="
sed -n '200,228p' "$F"
echo "===== K90 adreno8_hfi_send 实现 ====="
K=/root/star26/k90ref/kernel/xnu/files/bsd/dev/adreno8/adreno8_hfi.c
grep -n "adreno8_hfi_send" "$K" 2>/dev/null | head
LINE=$(grep -n "^adreno8_hfi_send" "$K" 2>/dev/null | head -1 | cut -d: -f1)
echo "at line $LINE"
if [ -n "$LINE" ]; then sed -n "$((LINE-3)),$((LINE+55))p" "$K"; fi
