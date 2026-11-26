#!/bin/bash
set -u
for t in s36 s37 s38 s39 s40 s41 s42 s43 p37 p38; do
  f=/root/star26/$t/work/root/etc/inject.conf
  [ -f "$f" ] || continue
  echo "--- $t  size=$(stat -c%s "$f")  mtime=$(stat -c%y "$f" | cut -d. -f1)"
  if grep -q "libannibale\.dylib" "$f"; then
    grep -n "libannibale\.dylib" "$f"
  else
    echo "    NO libannibale.dylib"
    if grep -q "backboardd" "$f"; then
      echo "    but backboardd mentioned:"
      grep -n "backboardd" "$f"
    fi
  fi
done
echo
echo "== any other inject.conf in tree =="
find /root/star26 -maxdepth 6 -name "inject.conf" 2>/dev/null | head -20
