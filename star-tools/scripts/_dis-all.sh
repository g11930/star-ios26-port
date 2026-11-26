#!/bin/bash
set -u
LIB=/root/star26/s41/work/root/lib/libannibale.dylib
OUT=/root/star26/dis-annibale.txt
llvm-objdump --arch=arm64 --disassemble "$LIB" > "$OUT" 2>/dev/null
echo "lines: $(wc -l < $OUT)"
echo "== _annibale_init range =="
awk '/<_annibale_init>:/{f=1} f&&/^$/{exit} f' "$OUT" | wc -l
