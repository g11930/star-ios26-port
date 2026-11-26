#!/bash
L=/mnt/c/ios26/s119-live.bin
strings -n 6 "$L" > /tmp/s119.txt
echo "===== 所有 handshake 应答 ====="
grep -i "Received handshake request from" /tmp/s119.txt | cut -c20-170
echo
echo "===== 涉及 39 的 runningboardd 行 ====="
grep "runningboardd\[" /tmp/s119.txt | grep -E " 39[\] :]|pid:39|:39]" | cut -c20-170 | head -10
echo
echo "===== backboardd 39 各线程最后活动时间（看主线程是否真的停住）====="
grep "backboardd\[39:" /tmp/s119.txt | awk '{print $2}' | cut -d. -f1 | sort -u | tail -8
echo
echo "===== SpringBoard 33 是否过了 handshake ====="
grep "SpringBoard\[33:" /tmp/s119.txt | grep -E "\[process\]|\[connection\]|frontboard|scene" | head -10 | cut -c20-160
echo
echo "===== 03:06 之后 backboardd 主线程(282) 有无输出 ====="
grep "backboardd\[39:282\]" /tmp/s119.txt | tail -3 | cut -c20-160
echo "===== DONE ====="
</bash>
