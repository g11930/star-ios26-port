#!/bin/bash
L=/mnt/d/ios26/now-090156.bin
echo "===== 1. 最新 PAC 状态 ====="
grep -a "pac: traps=" "$L" | tail -3
printf "pac page 行数: "; grep -a -c "pac: page" "$L"
echo "最后 3 条 page:"
grep -a "pac: page" "$L" | tail -3
echo
echo "===== 2. 崩溃/健康 ====="
for k in "panic:" "haltRestart" "not a platform binary" "refused translation" "space faulted"; do
  printf "%-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo
echo "===== 3. 启动进度里程碑 ====="
for k in "mount-phase-2" "unlockedEnvironmentMode" "unlockUIFromSource" "SpringBoard" "software PAuth active"; do
  printf "%-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
printf "last ts: "; grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -1
printf "lines: "; wc -l < "$L"
echo
echo "===== 4. FIPS 结果 ====="
grep -a -E "all tests PASSED|result = (true|false)|FAILED" "$L" | tail -5
