#!/bin/bash
for f in s130a s130b s131d; do
  echo "=== $f ==="
  strings -n 5 /mnt/c/ios26/$f-live.bin > /tmp/$f.txt
  grep -a -cE "Metal failed|Unsupported Metal|cannot create|nil device|no device" /tmp/$f.txt
  grep -aE "Metal failed|Unsupported Metal|cannot create|nil device|no device|CAMetalLayer|CGMetalContext|MTCreateSystemDefault" /tmp/$f.txt | sort -u | head -20
done
