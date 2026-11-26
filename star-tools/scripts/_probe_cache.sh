#!/bin/bash
set -u
echo "== s43 parts =="
ls -l /root/star26/s43/parts/ 2>/dev/null
echo
echo "== look for dyld shared caches anywhere in the build tree =="
find /root/star26/s43 /root/star26/s41 -maxdepth 4 -name "dyld_shared_cache*" 2>/dev/null | head -10
echo
echo "== does any cache mention libannibaleair? (name-only, first 3 hits) =="
find /root/star26 -maxdepth 5 -name "dyld_shared_cache*" 2>/dev/null | while read -r f; do
  if grep -qa "libannibaleair" "$f" 2>/dev/null; then
    echo "HIT: $f ($(stat -c%s "$f") bytes)"
  fi
done | head -5
echo "== cryptex contents in parts =="
for f in /root/star26/s43/parts/*; do
  echo "  $(basename "$f") $(stat -c%s "$f" 2>/dev/null)"
done
