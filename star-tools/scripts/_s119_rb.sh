#!/bash
L=/mnt/c/ios26/s119-live.bin
strings -n 6 "$L" > /tmp/s119.txt
echo "===== runningboardd 行数:"; grep -c "runningboardd\[" /tmp/s119.txt
echo
echo "===== runningboardd 最早 12 行 ====="
grep "runningboardd\[" /tmp/s119.txt | head -12 | cut -c20-160
echo
echo "===== runningboardd 03:03:5x 前后 ====="
grep "runningboardd\[" /tmp/s119.txt | grep -E "03:03:(4[5-9]|5[0-9])" | cut -c20-160 | head -14
echo
echo "===== runningboardd 最后 8 行 ====="
grep "runningboardd\[" /tmp/s119.txt | tail -8 | cut -c20-160
echo
echo "===== jetsam 相关 ====="
grep -i "jetsam" /tmp/s119.txt | cut -c20-170 | head -12
echo
echo "===== seeding / handshake 相关 ====="
grep -iE "seeding|handshake|process handle" /tmp/s119.txt | cut -c20-170 | head -12
echo "===== DONE ====="
</bash>
