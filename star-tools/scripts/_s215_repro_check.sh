#!/bin/bash
# s215 repro check: can mkapfs reproduce s208's ramdisk byte-for-byte from the extracted tree?
set -e
MKAPFS=/root/star26/hackios-xnu-userland/tools/apfs/mkapfs.py
ORIG=/root/star26/baseline/s208parts/ramdisk
STG=/tmp/s208rd
OUT=/tmp/s208-repro.apfs

echo "=== repro pack: mkapfs -z --plain fw, annibale=$STG ==="
python3 "$MKAPFS" -z --plain fw -o "$OUT" "annibale=$STG" 2>&1 | tail -3

echo "=== sizes ==="
stat -c "%s %n" "$ORIG" "$OUT"

echo "=== md5 ==="
md5sum "$ORIG" "$OUT"

echo "=== byte diff count ==="
cmp -l "$ORIG" "$OUT" 2>/dev/null | head -5 || true
echo "cmp bytes differ: $(cmp -l "$ORIG" "$OUT" 2>/dev/null | wc -l)"
