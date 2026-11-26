#!/bash
L=/mnt/c/ios26/s114c-live.bin
echo "===== 1) 关键计数 ====="
for pat in "start window server" "Initializing CAWindowServer" "P28FAULT" "annibale lib loaded"; do
  echo -n "  $pat: "; strings "$L" | grep -c "$pat"
done
echo -n "  backboardd termination: "; strings "$L" | grep -c "backboardd>:.*termination reported"
echo -n "  IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
echo -n "  selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo
echo "===== 2) 最新的 backboardd 状态 ====="
strings -n 6 "$L" | grep -E "backboardd\[" | tail -12 | cut -c1-150
echo
echo "===== 3) 最新全局（最后 15 行）====="
strings -n 6 "$L" | tail -15 | cut -c1-150
echo
echo "===== 4) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s114c-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
