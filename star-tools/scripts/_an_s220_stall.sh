#!/bin/bash
L=/mnt/d/ios26/now-090957.bin
echo "===== 最新时间戳 & 进度 ====="
printf "last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
printf "lines: "; wc -l < "$L"
echo "===== PAC 状态(是否在推进) ====="
grep -a "pac: traps=" "$L" | tail -3
grep -a "pac: page" "$L" | tail -2
echo "===== 启动里程碑 ====="
for k in "unlockedEnvironmentMode" "unlockUIFromSource" "fDeviceFirstUnlocked" "SpringBoard" "mount-phase-2" "boot unlock" "CoverSheet"; do
  printf "%-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo "===== 崩溃/卡死信号 ====="
for k in "panic:" "haltRestart" "hang" "stalled" "watchdog" "deadlock" "not a platform binary" "exited" "failed"; do
  printf "%-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo "===== 日志尾部 30 行 ====="
tail -c 4000 "$L" | tr -d '\0' | tail -25
