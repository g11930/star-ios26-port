#!/bin/bash
set -u
P=/root/ref/dada/kernel/xnu-12377.121.6-dada.patch
T=/root/star26/star-native
TMP=/tmp/dada_amfi

echo "=== diff headers between 83900 and 89000 ==="
awk 'NR>=83900 && NR<=89000 && /^diff --git/ {print NR": "$0}' $P

echo "=== our miniamfi_entitlements.cpp (123 lines, full) ==="
cat $T/libkern/amfi/miniamfi_entitlements.cpp

echo "=== our amfi.c (24 lines) ==="
cat $T/libkern/amfi/amfi.c

echo "=== our EXTERNAL_HEADERS/CodeSignature/ ==="
ls $T/EXTERNAL_HEADERS/CodeSignature/ 2>/dev/null
