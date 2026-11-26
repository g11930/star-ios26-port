#!/bash
L=/mnt/c/ios26/s105-live.bin
echo "===== 1) backboardd 是否打开 disp0 ====="
strings -n 6 "$L" | grep "IOSvcOpen" | grep -E "backboardd|disp0" | head -20
echo -n "IOSvcOpen 总数: "; strings "$L" | grep -c "IOSvcOpen"
echo
echo "===== 2) selector / notification / swap ====="
echo -n "selector 行: "; strings -n 8 "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "notification: "; strings "$L" | grep -c "notification port"
echo -n "tl s swap: "; strings -n 4 "$L" | grep -c -F "tl: s "
strings -n 8 "$L" | grep -E "MiniIOMobileFramebuffer: .* selector" | head -12
echo
echo "===== 3) 显示服务相关日志 ====="
strings -n 8 "$L" | grep -iE "framebuffer service|CLCD|disp0" | head -15
echo
echo "===== 4) 帧缓冲非零字节 ====="
python3 -c "
d=open('/mnt/c/ios26/s105-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo
echo "===== 5) 健康 ====="
echo -n "error=22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
