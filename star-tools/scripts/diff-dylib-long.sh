#!/bin/bash
OLD=/mnt/d/桌面/star26-deps/release/hackios-k90-v0.1.3/root/lib/libannibalemetal.dylib
NEW=/root/star26/p22/libannibalemetal.dylib
A=/tmp/old.long
B=/tmp/new.long
strings -n 30 "$OLD" | sort -u > "$A"
strings -n 30 "$NEW" | sort -u > "$B"
echo "old long strings: $(wc -l < "$A")   new long strings: $(wc -l < "$B")"
echo
echo "=== messages in NEW that OLD lacks ==="
comm -13 "$A" "$B"
echo
echo "=== messages in OLD that NEW lacks ==="
comm -23 "$A" "$B"
