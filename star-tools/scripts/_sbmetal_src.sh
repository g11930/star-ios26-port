#!/bash
echo "===== 找 sbmetal 实验库源码 ====="
grep -rl "IOAcceleratorES lookup" /root 2>/dev/null | head -10
echo
echo "===== s105 / s100 里的 sbmetal 行 ====="
for t in s105 s104 s103 s100 s99 s98; do
  f=/mnt/c/ios26/$t-live.bin
  if [ -f "$f" ]; then
    echo "-- $t"
    strings -n 8 "$f" | grep -F "ioAcceleratorES" | head -3
    strings -n 8 "$f" | grep -F "registration failed" | head -3
  fi
done
echo "===== DONE ====="
</bash>
