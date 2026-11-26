#!/bash
L=/mnt/c/ios26/s122-live.bin
strings -n 6 "$L" > /tmp/s122.txt
echo "===== 03:03:56 ~ 03:05:25 之间全局日志量 ====="
grep -cE "2025-12-10 03:0[34]:" /tmp/s122.txt
echo "--- 该窗口内的进程分布（前 12）:"
grep -oE "2025-12-10 03:0[34]:[0-9.]+\+0800 [a-zA-Z0-9_.-]+\[" /tmp/s122.txt | sed -E 's/.*\+0800 //' | sort | uniq -c | sort -rn | head -12
echo
echo "--- 该窗口内 03:03:56-03:04:10 抽样:"
grep -E "2025-12-10 03:03:5[6-9]|2025-12-10 03:04:0[0-9]" /tmp/s122.txt | cut -c20-130 | head -12
echo
echo "===== EXECDBG 总数 vs 时间跨度 ====="
grep -c "EXECDBG: loading" /tmp/s122.txt
echo
echo "===== bootstrap 相关：lookup 失败的痕迹 ====="
grep -iE "bootstrap|No such process|failed to do a bootstrap" /tmp/s122.txt | cut -c20-150 | head -10
echo "===== DONE ====="
</bash>
