#!/bash
L=/mnt/c/ios26/s114-live.bin
strings -n 6 "$L" > /tmp/s114.txt
echo "===== 1) backboardd 启动序列（Common start ...）====="
grep -nE "start window server|StartWindowServer|StartWindowServer|\[Display\]|initializ|Common\] start" /tmp/s114.txt | head -20
echo
echo "===== 2) backboardd 最后 25 行（它现在在干什么）====="
grep -nE "backboardd\[" /tmp/s114.txt | tail -25
echo
echo "===== 3) SpringBoard 状态 ====="
grep -nE "SpringBoard\[" /tmp/s114.txt | tail -12
echo "===== DONE ====="
</bash>
