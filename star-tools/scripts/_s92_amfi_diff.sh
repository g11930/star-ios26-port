#!/bin/bash
# Read-only diagnosis: compare our amfi files vs dada's, find identifier path
set -u
P=/root/ref/dada/kernel/xnu-12377.121.6-dada.patch
T=/root/star26/star-native
TMP=/tmp/dada_amfi
mkdir -p $TMP

# extract dada miniamfi.c (new file: lines 83933..84197) and miniamfi_entitlements.cpp (84198..88381)
sed -n '83933,84197p' $P | sed 's/^+//' > $TMP/miniamfi.c
sed -n '84203,88381p' $P | sed 's/^+//' > $TMP/miniamfi_entitlements.cpp

echo "=== extracted sizes ==="
wc -l $TMP/miniamfi.c $TMP/miniamfi_entitlements.cpp
echo "=== our files ==="
wc -l $T/libkern/amfi/*.c* $T/libkern/amfi/*.h 2>/dev/null
echo "=== diff miniamfi.c (ours vs dada) ==="
diff -u $T/libkern/amfi/miniamfi.c $TMP/miniamfi.c | head -40
echo "=== diff miniamfi_entitlements.cpp summary ==="
diff -u $T/libkern/amfi/miniamfi_entitlements.cpp $TMP/miniamfi_entitlements.cpp > $TMP/ent.diff
echo "diff lines: $(wc -l < $TMP/ent.diff)"
head -60 $TMP/ent.diff
