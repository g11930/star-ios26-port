#!/bin/bash
# 对比 s217(pac_patch=0) 与 s220(pac_patch=2) 启动早期 traps 增长率
for L in /mnt/d/ios26/now-083621.bin /mnt/d/ios26/now-085730.bin; do
  echo "========== $L =========="
  echo "--- first 3 pac traps ---"
  grep -a "pac: traps=" "$L" | head -3
  echo "--- last 3 pac traps ---"
  grep -a "pac: traps=" "$L" | tail -3
  echo "--- total lines / timespan ---"
  printf "lines="; wc -l < "$L"
  printf "first ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | head -1
  printf "last  ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
done
