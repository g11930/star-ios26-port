#!/bash
L=/mnt/c/ios26/s112-live.bin
echo "===== 1) annibale 全部输出 ====="
strings -n 6 "$L" | grep -E "annibale" | head -40
echo
echo "===== 2) 关键判据 ====="
echo -n "detectDisplays mismatch: "; strings "$L" | grep -c "not what was expected"
echo -n "keep_metal 行: "; strings "$L" | grep -c "keep_metal_from_core_animation"
echo -n "hooks INCOMPLETE: "; strings "$L" | grep -c "window server hooks INCOMPLETE"
echo -n "hooks installed: "; strings "$L" | grep -c "window server hooks installed"
echo
echo "===== 3) fb / selector / swap ====="
echo -n "IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
strings -n 6 "$L" | grep "IOSvcOpen" | grep -iE "disp0|backboardd" | head -6
echo -n "selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "tl s: "; strings "$L" | grep -c -F "tl: s "
echo -n "swap: "; strings "$L" | grep -c -iE "swap|flip"
echo
echo "===== 4) Metal ====="
strings -n 8 "$L" | grep -F "registration completed" | head -3
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s112-frame.raw','rb').read()
nz=sum(1 for b in d if b)
print('len',len(d),'nonzero',nz)
"
echo "===== DONE ====="
</bash>
