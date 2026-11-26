#!/bash
L=/mnt/c/ios26/s120-live.bin
strings -n 6 "$L" > /tmp/s120.txt
echo "===== RB 在 03:03:5x - 03:05:4x 的首尾片段 ====="
grep "runningboardd\[" /tmp/s120.txt | grep -oE "03:0[3-5]:[0-9]+.*" > /tmp/rb.txt
head -6 /tmp/rb.txt | cut -c1-170
echo "  ..."
echo "--- 03:03:5x 段（T+40~60s）:"
grep -E "^03:03:5" /tmp/rb.txt | cut -c1-170 | head -8
echo "--- 03:04:0x-03:04:5x 段抽样:"
grep -E "^03:04:" /tmp/rb.txt | awk 'NR%40==1' | cut -c1-170 | head -10
echo "--- 03:05:3x-03:05:5x 段:"
grep -E "^03:05:[345]" /tmp/rb.txt | cut -c1-170 | head -12
echo
echo "===== [process] / [workspace] / monitor 类消息 ====="
grep -E "\[process\]|\[workspace\]|\[monitor\]" /tmp/s120.txt | cut -c20-160 | head -14
echo "===== DONE ====="
</bash>
