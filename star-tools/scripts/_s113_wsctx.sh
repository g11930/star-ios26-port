#!/bash
L=/mnt/c/ios26/s113-live.bin
strings -n 6 "$L" > /tmp/s113.txt
echo "===== CAWindowServer 初始化前后 12 行（第一次）====="
grep -n "Initializing CAWindowServer" /tmp/s113.txt | head -3
for n in $(grep -n "Initializing CAWindowServer" /tmp/s113.txt | cut -d: -f1 | head -2); do
  echo "--- 从第 $n 行起:"
  sed -n "$((n-3)),$((n+12))p" /tmp/s113.txt
done
echo
echo "===== backboardd 死亡/重启原文 ====="
grep -nE "backboardd.?\[?39|backboardd.?\[?145|backboardd.?\[?156" /tmp/s113.txt | tail -25
echo
echo "===== ReportCrash / 异常 ====="
grep -nE "ReportCrash|Exception|exception|terminat|killing|SIGKILL|signal 9" /tmp/s113.txt | tail -20
echo "===== DONE ====="
</bash>
