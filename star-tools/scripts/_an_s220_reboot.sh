#!/bin/bash
for L in /mnt/d/ios26/now-090156.bin /mnt/d/ios26/now-090957.bin /mnt/d/ios26/now-091348.bin; do
  echo "========== $L =========="
  printf "size: "; stat -c%s "$L"
  # 唯一启动标记：每次内核启动只打印一次
  for k in "StarDisk: published" "boot-args" "Starting launchd on star" "Darwin Kernel Version" "root fs mounted" "loaded kernel";
    do printf "  %-32s %s\n" "$k" "$(grep -a -c "$k" "$L")"; done
  printf "  last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
  printf "  first ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | head -1
done
