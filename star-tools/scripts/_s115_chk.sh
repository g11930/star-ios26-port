#!/bash
L=/mnt/c/ios26/s115-live.bin
echo "===== 1) 关键计数 ====="
for pat in "start window server" "Initializing CAWindowServer" "P28FAULT" "annibale lib loaded" "annibale: metal"; do
  echo -n "  $pat: "; strings "$L" | grep -c "$pat"
done
echo -n "  backboardd termination: "; strings "$L" | grep -c "backboardd>:.*termination reported"
echo -n "  IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
echo -n "  selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "  flip/swap: "; strings "$L" | grep -c -E "swap|flip:"
echo
echo "===== 2) backboardd [Common] 全序列 ====="
strings -n 6 "$L" | grep -E "\[Common\]" | grep -E "start|ready" | cut -c1-135 | head -30
echo
echo "===== 3) WindowServer / display ====="
strings -n 8 "$L" | grep -iE "WindowServer|AppleDisplay|EAGLServer|Unable to query displays" | cut -c1-150 | head -12
echo
echo "===== 4) disp0 / fb 打开 ====="
strings -n 6 "$L" | grep "IOSvcOpen" | grep -iE "disp0|Framebuffer|backboardd" | head -8
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s115-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
