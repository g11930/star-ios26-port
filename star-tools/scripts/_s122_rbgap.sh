#!/bash
L=/mnt/c/ios26/s122-live.bin
strings -n 6 "$L" > /tmp/s122.txt
grep "runningboardd\[" /tmp/s122.txt | grep -E "03:03:5[5-9]|03:04:|03:05:[0-2]" > /tmp/rbgap.txt
echo "行数: $(wc -l < /tmp/rbgap.txt)"
echo "===== 前 16 条 ====="
head -16 /tmp/rbgap.txt | cut -c20-160
echo
echo "===== 中段抽样（每 15 条取 1）====="
awk 'NR%15==3' /tmp/rbgap.txt | cut -c20-160 | head -8
echo
echo "===== 最后 12 条 ====="
tail -12 /tmp/rbgap.txt | cut -c20-160
echo
echo "===== 不同线程数 ====="
grep -oE "runningboardd\[30:[0-9]+\]" /tmp/rbgap.txt | sort | uniq -c | sort -rn | head -8
echo "===== DONE ====="
</bash>
