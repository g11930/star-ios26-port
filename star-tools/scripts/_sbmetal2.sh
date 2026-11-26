#!/bash
echo "===== shim 里 IOAcceleratorES 查找逻辑 ====="
grep -n -B 8 -A 20 "IOAcceleratorES lookup" /root/star26/hackios-xnu-userland/userland/src/inject/sb_metal_experiment.m | head -60
echo
echo "===== 历史日志里的 sbmetal 输出 ====="
for t in s109 s107 s105 s103 s100; do
  f=/mnt/c/ios26/$t-live.bin
  [ -f "$f" ] || continue
  echo "-- $t"
  strings -n 8 "$f" | grep -F "IOAcceleratorES" | head -3
  strings -n 8 "$f" | grep -F "registration completed" | head -3
done
echo "===== DONE ====="
</bash>
