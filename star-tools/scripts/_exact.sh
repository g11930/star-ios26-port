#!/bin/bash
F=/root/star26/star-native/bsd/dev/star/annibale_adreno.c
sed -n '2310,2316p' "$F" | cat -A
echo "=== 再确认 2329-2342 前导 ==="
sed -n '2329,2345p' "$F"
