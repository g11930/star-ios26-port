#!/bash
L=/mnt/c/ios26/s119-live.bin
strings -n 6 "$L" > /tmp/s119.txt
echo "===== runningboardd 03:03:52 → 03:05:40 活动 ====="
grep "runningboardd\[" /tmp/s119.txt | grep -E "03:0[3-5]:" | awk '{print $2, $0}' | sed -n '1,200p' | cut -c1-165 | grep -E "03:0[3-5]:" | tail -40
echo
echo "===== seed 相关（全日志）====="
grep -iE "seed|databas|FrontBoard" /tmp/s119.txt | cut -c1-165 | head -14
echo
echo "===== RB 的空闲/阻塞痕迹：thread 338 之后的输出 ====="
grep "runningboardd\[30:338\]" /tmp/s119.txt | tail -6 | cut -c20-165
echo "===== DONE ====="
</bash>
