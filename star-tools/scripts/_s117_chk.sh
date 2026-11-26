#!/bash
L=/mnt/c/ios26/s117-live.bin
strings -n 6 "$L" > /tmp/s117.txt
echo "===== 1) 关键计数 ====="
for pat in "start window server" "Initializing CAWindowServer" "P28FAULT" "annibale lib loaded" "Unable to query displays" "annibale: metal"; do
  echo -n "  $pat: "; grep -c "$pat" /tmp/s117.txt
done
echo -n "  backboardd termination: "; grep -c "backboardd>:.*termination reported" /tmp/s117.txt
echo -n "  IOSvcOpen: "; grep -c "IOSvcOpen" /tmp/s117.txt
echo -n "  selector: "; grep -c "MiniIOMobileFramebuffer: .* selector" /tmp/s117.txt
echo -n "  swap/flip: "; grep -c -E "swap|flip:" /tmp/s117.txt
echo
echo "===== 2) backboardd [Common] 序列 ====="
grep -E "\[Common\]" /tmp/s117.txt | grep -E "start|ready" | cut -c1-130 | head -26
echo
echo "===== 3) WindowServer / display ====="
grep -iE "WindowServer|AppleDisplay|EAGLServer|Unable to query displays|start window server" /tmp/s117.txt | cut -c1-150 | head -12
echo
echo "===== 4) disp0 打开 ====="
grep "IOSvcOpen" /tmp/s117.txt | grep -iE "disp0|Framebuffer|backboardd" | head -8
echo
echo "===== 5) 全局最后 8 行 ====="
tail -8 /tmp/s117.txt | cut -c1-140
echo
echo "===== 6) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s117-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
