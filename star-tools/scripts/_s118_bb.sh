#!/bash
L=/mnt/c/ios26/s118-live.bin
strings -n 6 "$L" > /tmp/s118.txt
echo "--- backboardd[ 行数:"; grep -c "backboardd\[" /tmp/s118.txt
echo "--- backboardd[ 最早/最晚:"; grep "backboardd\[" /tmp/s118.txt | head -3 | cut -c1-120; echo ...; grep "backboardd\[" /tmp/s118.txt | tail -3 | cut -c1-120
echo
echo "--- 其他提及 backboardd 的（非 [pid]）:"
grep "backboardd" /tmp/s118.txt | grep -v "backboardd\[" | head -8 | cut -c1-130
echo
echo "--- SpringBoard 是否有窗口服务器相关:"
grep -E "SpringBoard\[" /tmp/s118.txt | tail -6 | cut -c1-130
echo "===== DONE ====="
</bash>
