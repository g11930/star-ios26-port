#!/bash
for t in s109 s111 s113; do
  L=/mnt/c/ios26/$t-live.bin
  [ -f "$L" ] || continue
  echo "===== $t ====="
  echo -n "  CAWindowServer 初始化: "; strings "$L" | grep -c "Initializing CAWindowServer"
  echo -n "  P28FAULT 总数: "; strings "$L" | grep -c "P28FAULT"
  strings -n 8 "$L" | grep "P28FAULT" | head -4
  echo -n "  backboardd termination: "; strings "$L" | grep -c "backboardd>:.* termination reported"
  strings -n 8 "$L" | grep "termination reported" | grep backboardd | head -3
  echo -n "  annibale lib loaded: "; strings "$L" | grep -c "annibale lib loaded"
  echo -n "  window server hooks: "; strings "$L" | grep -c "window server hooks"
done
echo "===== DONE ====="
</bash>
