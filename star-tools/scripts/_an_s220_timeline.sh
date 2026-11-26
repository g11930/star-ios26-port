#!/bin/bash
# 对比 s217 vs s220 到达 unlock 标记的时间线
echo "===== s217 (pac_patch=0) 各日志的 unlock 进度 ====="
for L in /mnt/d/ios26/now-083621.bin /mnt/d/ios26/s217-mid-073704.bin; do
  [ -f "$L" ] || continue
  echo "--- $L ---"
  printf "  fDeviceFirstUnlocked: "; grep -a -c "fDeviceFirstUnlocked" "$L"
  printf "  unlockedEnvironmentMode: "; grep -a -c "unlockedEnvironmentMode" "$L"
  printf "  SpringBoard: "; grep -a -c "SpringBoard" "$L"
  printf "  last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
  printf "  pac traps: "; grep -a "pac: traps=" "$L" | tail -1
done
echo
echo "===== s220 (pac_patch=2) 时间线 ====="
for L in /mnt/d/ios26/now-085730.bin /mnt/d/ios26/now-090957.bin /mnt/d/ios26/now-091348.bin; do
  echo "--- $L ---"
  printf "  fDeviceFirstUnlocked: "; grep -a -c "fDeviceFirstUnlocked" "$L"
  printf "  SpringBoard: "; grep -a -c "SpringBoard" "$L"
  printf "  last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
  printf "  pac traps: "; grep -a "pac: traps=" "$L" | tail -1
done
