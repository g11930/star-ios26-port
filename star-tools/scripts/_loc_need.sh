#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
echo "=== need() definition ==="
grep -n "need(struct block\|^need(" "$F" | head
echo "=== rd() definition ==="
grep -n "^rd(\|rd(uint32_t\|rd(volatile" "$F" | head
echo "=== tsens block context 4118-4133 ==="
sed -n '4118,4133p' "$F"
