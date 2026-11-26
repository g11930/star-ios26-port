#!/bin/bash
OLD=/mnt/d/桌面/star26-deps/release/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
NEW=/root/star26/p22/libannibalemetal.dylib
A=/tmp/old.strings
B=/tmp/new.strings
strings "$OLD" | sort -u > "$A"
strings "$NEW" | sort -u > "$B"
echo "old unique strings: $(wc -l < "$A")"
echo "new unique strings: $(wc -l < "$B")"
echo
echo "=== only in NEW (first 40) ==="
comm -13 "$A" "$B" | head -40
echo
echo "=== only in OLD (first 40) ==="
comm -23 "$A" "$B" | head -40
