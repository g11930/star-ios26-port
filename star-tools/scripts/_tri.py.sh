#!/bin/bash
for f in s130a s130b s131d; do
  echo "=== $f ==="
  strings -n 5 /mnt/c/ios26/$f-live.bin > /tmp/$f.txt
  grep -a -iE "triangle|annibalemetal|libannibalemetal|metal_props|annibale:" /tmp/$f.txt | grep -av "^-rw" | head -25
done
