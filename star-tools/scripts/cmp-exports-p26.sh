#!/bin/bash
# Exported (T) rwa_* symbols: what libannibalemetal.dylib resolves by name at load.
NEW=/root/star26/p26/libannibaleair.dylib
OLD=/root/star26/release/v0.1.3/hackios-k90-v0.1.3/root/lib/libannibaleair.dylib.v013
llvm-nm --defined-only "$NEW" 2>/dev/null | awk '$2=="T" && $3 ~ /^_rwa_/ {print $3}' | LC_ALL=C sort > /tmp/newT.txt
llvm-nm --defined-only "$OLD" 2>/dev/null | awk '$2=="T" && $3 ~ /^_rwa_/ {print $3}' | LC_ALL=C sort > /tmp/oldT.txt
echo "exports: new $(wc -l < /tmp/newT.txt)  old $(wc -l < /tmp/oldT.txt)"
echo "=== exported by old, MISSING in new ==="
comm -13 /tmp/newT.txt /tmp/oldT.txt
echo "=== new only ==="
comm -23 /tmp/newT.txt /tmp/oldT.txt
