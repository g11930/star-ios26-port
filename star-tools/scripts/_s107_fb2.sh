#!/bash
L=/mnt/c/ios26/s107-live.bin
echo "===== MiniIOMobileFramebuffer 自身日志 ====="
strings -n 8 "$L" | grep "MiniIOMobileFramebuffer" | head -20
echo
echo "===== flip / swap 计数 ====="
for k in "flip" "tl: s" "tl: l" "P34" "swap"; do
  printf '%-10s %s\n' "$k" "$(strings "$L" | grep -c -F "$k")"
done
echo
echo "===== s100 open 探针 ====="
strings -n 8 "$L" | grep -E "s100" | head -5
echo
echo "===== backboardd 最后 12 条 ====="
strings -n 20 "$L" | grep "backboardd" | tail -12
echo "===== DONE ====="
</bash>
