#!/bash
L=/mnt/c/ios26/s119-live.bin
strings -n 6 "$L" > /tmp/s119.txt
echo "===== 1) 计数 ====="
for pat in "annibale lib loaded" "start window server" "Initializing CAWindowServer" "window server hooks" "P28FAULT" "Unable to query displays" "start HID system" "[Common] starting backboardd"; do
  echo -n "  $pat = "; grep -c "$pat" /tmp/s119.txt
done
echo -n "  backboardd termination = "; grep -c "backboardd>:.*termination reported" /tmp/s119.txt
echo -n "  IOSvcOpen = "; grep -c "IOSvcOpen" /tmp/s119.txt
echo -n "  selector = "; grep -c "selector" /tmp/s119.txt
echo
echo "===== 2) annibale 行 ====="
grep "annibale" /tmp/s119.txt | grep -v motd | cut -c1-130 | head -14
echo
echo "===== 3) backboardd 生命周期 ====="
grep -E "backboardd\[" /tmp/s119.txt | grep -E "\[Common\]|start |ready|Initializing|window server|Removing all" | cut -c1-150 | head -18
echo
echo "===== 4) disp0 ====="
grep -i "disp0" /tmp/s119.txt | cut -c1-140 | head -10
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s119-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
