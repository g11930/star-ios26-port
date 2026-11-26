#!/bash
L=/mnt/c/ios26/s111-live.bin
echo "===== 1) libannibale 是否注入 backboardd ====="
strings -n 8 "$L" | grep -E "annibale lib loaded|annibale:" | head -20
echo -n "annibale 行总数: "; strings "$L" | grep -c "annibale"
echo
echo "===== 2) detectDisplays 钩子结果 ====="
strings -n 8 "$L" | grep -iE "detectDisplays|window server hooks|not what was expected" | head -10
echo
echo "===== 3) fb 是否被打开 / selector ====="
echo -n "IOSvcOpen total: "; strings "$L" | grep -c "IOSvcOpen"
strings -n 6 "$L" | grep "IOSvcOpen" | grep -iE "backboardd|disp0" | head -8
echo -n "MiniIOMobileFramebuffer selector: "; strings -n 8 "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "tl s: "; strings -n 4 "$L" | grep -c -F "tl: s "
echo
echo "===== 4) Metal 注册 ====="
strings -n 8 "$L" | grep -F "registration completed" | head -4
echo
echo "===== 5) 帧缓冲 ====="
python3 -c "
d=open('/mnt/c/ios26/s111-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo -n "error22: "; strings "$L" | grep -c "error=22"
echo "===== DONE ====="
</bash>
