#!/bash
L=/mnt/c/ios26/s114-live.bin
echo "===== 1) 崩溃是否消失 ====="
echo -n "P28FAULT: "; strings "$L" | grep -c "P28FAULT"
strings -n 8 "$L" | grep "P28FAULT" | head -3
echo -n "backboardd termination: "; strings "$L" | grep -c "backboardd>:.*termination reported"
echo -n "annibale lib loaded: "; strings "$L" | grep -c "annibale lib loaded"
echo -n "CAWindowServer 初始化: "; strings "$L" | grep -c "Initializing CAWindowServer"
echo
echo "===== 2) 显示链路是否终于动了 ====="
echo -n "IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
strings -n 6 "$L" | grep "IOSvcOpen" | grep -iE "disp0|Framebuffer" | head -6
echo -n "selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "flip/swap: "; strings "$L" | grep -c -E "flip:|swap"
strings -n 8 "$L" | grep -E "flip:|swap" | head -8
echo
echo "===== 3) WindowServer / display 相关 ====="
strings -n 8 "$L" | grep -iE "WindowServer|AppleDisplay|EAGLServer|IOMobileFramebuffer" | head -20
echo
echo "===== 4) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s114-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
