#!/bash
L=/mnt/c/ios26/s118-live.bin
strings -n 6 "$L" > /tmp/s118.txt
echo "===== 1) 关键计数 ====="
for pat in "start window server" "Initializing CAWindowServer" "P28FAULT" "window server hooks" "Unable to query displays" "start HID system"; do
  echo -n "  $pat: "; grep -c "$pat" /tmp/s118.txt
done
echo -n "  backboardd termination: "; grep -c "backboardd>:.*termination reported" /tmp/s118.txt
echo -n "  IOSvcOpen: "; grep -c "IOSvcOpen" /tmp/s118.txt
echo -n "  selector: "; grep -c "MiniIOMobileFramebuffer: .* selector" /tmp/s118.txt
echo -n "  swap/flip: "; grep -c -E "swap|flip:" /tmp/s118.txt
echo
echo "===== 2) backboardd [Common] ====="
grep -E "\[Common\]" /tmp/s118.txt | grep -E "start|ready" | cut -c1-130 | head -26
echo
echo "===== 3) WindowServer / display ====="
grep -iE "WindowServer|AppleDisplay|EAGLServer|start window server" /tmp/s118.txt | cut -c1-150 | head -12
echo
echo "===== 4) annibale 行 ====="
grep "annibale:" /tmp/s118.txt | cut -c1-120 | sort | uniq -c | sort -rn | head -10
echo
echo "===== 5) disp0 / fb ====="
grep "IOSvcOpen" /tmp/s118.txt | grep -iE "disp0|Framebuffer|backboardd" | head -8
echo
echo "===== 6) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s118-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
