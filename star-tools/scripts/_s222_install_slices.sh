#!/bin/bash
set -u
D=/root/dsc26/System/Library/Caches/com.apple.dyld
F=/root/dsc26_fix
for n in 35 72 83; do
  f="dyld_shared_cache_arm64e.${n}.dyldlinkedit"
  echo "=== $f ==="
  echo -n "  old size: "; stat -c %s "$D/$f" 2>/dev/null || echo MISSING
  echo -n "  new size: "; stat -c %s "$F/$f" 2>/dev/null || echo MISSING
  echo -n "  new magic: "; head -c 16 "$F/$f" 2>/dev/null; echo
done
