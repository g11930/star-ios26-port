#!/bash
L=/mnt/c/ios26/s114-live.bin
strings -n 6 "$L" > /tmp/s114.txt
echo "===== backboardd pid39 的 [Common] 启动序列全部 ====="
grep -E "backboardd\[39:.*\[Common\]" /tmp/s114.txt | head -40
echo
echo "===== 是否出现 start window server / Display ====="
grep -c "start window server" /tmp/s114.txt
grep -E "\[Display\]|WindowServer" /tmp/s114.txt | head -10
echo
echo "===== 03:03:52~03:04:05 之间 pid39 的行（卡在哪）====="
grep -E "backboardd\[39:" /tmp/s114.txt | sed -n '1,60p' | cut -c1-160
echo "===== DONE ====="
</bash>
