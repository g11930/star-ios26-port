#!/bin/bash
L=/mnt/d/ios26/now-085730.bin
echo "===== 1. PAC page 改写 (最关键) ====="
grep -a "pac: page" "$L" | head -8
printf "pac: page 行数 = "
grep -a -c "pac: page" "$L"
echo
echo "===== 2. PAC traps 状态 ====="
grep -a "pac: traps=" "$L" | tail -5
echo
echo "===== 3. fips / mount / boot task ====="
for k in "fips" "post_mount" "mount-phase-2" "fips boot task" "cc_fips" "haltRestart" "panic:" "not a platform binary"; do
  printf "%-28s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo
echo "===== 4. 关键 fips/mount 上下文 ====="
grep -a -i -E "fips|mount-phase|not a platform binary|haltRestart" "$L" | tail -20
echo
echo "===== 5. 启动进度 (最后时间戳 + 用户态活动) ====="
grep -a -oE "[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}" "$L" | tail -3
printf "launchd lines: "; grep -a -c "launchd" "$L"
printf "SpringBoard lines: "; grep -a -c "SpringBoard" "$L"
printf "software PAuth: "; grep -a -c "software PAuth active" "$L"
