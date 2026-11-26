#!/bin/bash
for f in s130a s130b s131d; do
  echo "=== $f ==="
  strings -n 5 /mnt/c/ios26/$f-live.bin > /tmp/$f.txt
  grep -aiE 'AnnibaleGPU|annibale_gpu|adreno|RBBM|a6xx|freedreno|gpu=' /tmp/$f.txt | sort -u | head -20
done
echo "=== kernel image: does it contain the strings? ==="
strings -n 6 /root/star26/s111/parts/kernel | grep -aiE 'AnnibaleGPU|adreno|RBBM|a6xx' | sort -u | head -15
