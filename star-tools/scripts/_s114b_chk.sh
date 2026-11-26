#!/bash
L=/mnt/c/ios26/s114b-live.bin
echo "===== 1) 是否走到窗口服务器 ====="
echo -n "start window server: "; strings "$L" | grep -c "start window server"
echo -n "Initializing CAWindowServer: "; strings "$L" | grep -c "Initializing CAWindowServer"
echo -n "P28FAULT: "; strings "$L" | grep -c "P28FAULT"
echo -n "backboardd termination: "; strings "$L" | grep -c "backboardd>:.*termination reported"
echo
echo "===== 2) backboardd [Common] 序列 ====="
strings -n 6 "$L" | grep -E "\[Common\]" | grep -E "start|ready" | head -20
echo
echo "===== 3) 显示 / fb ====="
echo -n "IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
strings -n 6 "$L" | grep "IOSvcOpen" | grep -iE "disp0|Framebuffer" | head -5
echo -n "selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "swap/flip: "; strings "$L" | grep -c -E "swap|flip:"
echo
echo "===== 4) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s114b-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
