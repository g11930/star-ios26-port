#!/bin/bash
L=/mnt/d/ios26/s217-mid-073704.bin
echo "=== [1] GPU: 10 speeds + 840 vote ==="
grep -a -E "10 speeds, .*MHz|the speed wanted|GMU accepts the speed|THE GPU STAYS" "$L" | head -6
echo
echo "=== [2] dylib: software icon patch must be GONE, K90 unlock present ==="
for s in software_icons_installed shouldForceBitmapImages "waiting for CoverSheet" activation_installed; do
  printf "  %-28s %s\n" "$s" "$(grep -a -c "$s" "$L")"
done
echo
echo "=== [3] panic / fault ==="
printf "  panic( count: %s\n" "$(grep -a -c 'panic(' "$L")"
grep -a -E "KERNEL FAULT|FASTBOOT RECOVERY|Debugger message" "$L" | head -3
echo
echo "=== [4] UI / unlock ==="
for k in "presentationsLock" "lock screen transition" "Unlocked since boot" "sb26: unlock" "unlockedEnvironmentMode"; do
  printf "  %-26s %s\n" "$k" "$(grep -a -c "$k" "$L")"
done
echo
echo "=== [5] GPU users ==="
grep -a -oE "annibalemetal\[[a-z]+ [0-9]+\]" "$L" | sort | uniq -c | sort -rn | head -5
echo
echo "=== [6] latest applog time ==="
grep -a -oE "2025-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}" "$L" | tail -1
