#!/bin/bash
set -u
D=/root/dsc26/System/Library/Caches/com.apple.dyld
F=/root/dsc26_fix
B=/root/dsc26_empty_backup
mkdir -p "$B"
for n in 35 72 83; do
  f="dyld_shared_cache_arm64e.${n}.dyldlinkedit"
  echo "=== $f ==="
  if [ ! -f "$B/$f" ]; then cp "$D/$f" "$B/$f"; fi
  cp "$F/$f" "$D/$f"
  echo "  installed: $(stat -c %s "$D/$f") bytes; backup at $B/$f"
done
