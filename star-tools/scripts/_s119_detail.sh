#!/bash
L=/mnt/c/ios26/s119-live.bin
strings -n 6 "$L" > /tmp/s119.txt
echo "===== annibale lib loaded 行 ====="
grep "annibale lib loaded" /tmp/s119.txt | cut -c1-140
echo
echo "===== window server hooks 行 ====="
grep -n "window server hooks" /tmp/s119.txt | cut -c1-160
echo
echo "===== 该行前后 6 行 ====="
n=$(grep -n "window server hooks" /tmp/s119.txt | head -1 | cut -d: -f1)
if [ -n "$n" ]; then sed -n "$((n-6)),$((n+6))p" /tmp/s119.txt | cut -c1-150; fi
echo
echo "===== backboardd 主线程最后三行 ====="
grep -E "backboardd\[39:(282|328)\]" /tmp/s119.txt | tail -4 | cut -c1-150
echo
echo "===== plist 生效情况（launchd job 行）====="
grep -iE "backboardd" /tmp/s119.txt | grep -iE "launchd|job|StartInter" | head -8 | cut -c1-150
echo "===== DONE ====="
</bash>
