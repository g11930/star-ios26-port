#!/bash
L=/mnt/c/ios26/s115-live.bin
strings -n 6 "$L" > /tmp/s115.txt
echo "===== 主线程 tid 277 的最后动作 ====="
grep -E "backboardd\[39:277\]" /tmp/s115.txt | cut -c1-150 | tail -12
echo
echo "===== 03:03:54 之后 pid39 所有行（按出现顺序前 20 条）====="
grep -E "backboardd\[39:" /tmp/s115.txt | awk -F' ' '$2>"03:03:54"' | cut -c1-140 | head -20
echo
echo "===== 是否出现 HID system / AttentionAwareness / GS ====="
for pat in "start HID system" "AttentionAwareness" "start GS" "BKIOHID" "IOHIDEventSystemClientCreate"; do
  echo -n "  $pat: "; grep -c "$pat" /tmp/s115.txt
done
echo
echo "===== 是否有超时/watchdog 杀掉 backboardd ====="
grep -iE "watchdog|startup (timeout|deadline)|exceeded|timed out" /tmp/s115.txt | cut -c1-140 | head -10
echo "===== DONE ====="
</bash>
