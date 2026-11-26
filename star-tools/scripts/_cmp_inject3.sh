#!/bin/bash
set -u
for t in s33 s34 s35 s36; do
  f=/root/star26/$t/work/root/etc/inject.conf
  [ -f "$f" ] || f=/root/star26/$t/verify/root/etc/inject.conf
  if [ -f "$f" ]; then
    echo "=== $t  size=$(stat -c%s "$f")  mtime=$(stat -c%y "$f" | cut -d. -f1)"
    head -3 "$f"
    echo "    lines=$(grep -c . "$f")"
  else
    echo "=== $t  (no inject.conf)"
  fi
done
