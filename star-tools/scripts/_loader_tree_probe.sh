#!/bin/bash
echo "=== build trees ==="
for d in /root/star-build/xnuloader /root/star26/xnuloader /root/star26/star-native/xnuloader; do
  [ -d "$d" ] && echo "EXISTS $d" || echo "missing $d"
done

echo
echo "=== find xnuloader dirs ==="
find /root -maxdepth 4 -type d -name "xnuloader" 2>/dev/null | head

echo
echo "=== find loader.c in root ==="
find /root -maxdepth 5 -name "loader.c" 2>/dev/null | head

echo
echo "=== efi.h input structs (if any) ==="
for f in $(find /root -maxdepth 5 -name "efi.h" 2>/dev/null | head -3); do
  echo "--- $f ($(wc -l < "$f") lines) ---"
  grep -n -iE "input_key|simple_text|con_in|scan_code|unicode_char" "$f" | head -12
done
