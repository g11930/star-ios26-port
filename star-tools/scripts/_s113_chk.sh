#!/bash
L=/mnt/c/ios26/s113-live.bin
echo "===== 1) 库是否被 dyld 接受 ====="
echo -n "annibale lib loaded: "; strings "$L" | grep -c "annibale lib loaded"
strings -n 6 "$L" | grep "annibale lib loaded" | head -3
echo
echo "===== 2) detectDisplays 判据 ====="
echo -n "mismatch 行: "; strings "$L" | grep -c "not what was expected"
strings -n 6 "$L" | grep -E "detectDisplays|annibale:" | head -15
echo
echo "===== 3) 显示链路 ====="
echo -n "IOSvcOpen: "; strings "$L" | grep -c "IOSvcOpen"
echo -n "selector: "; strings "$L" | grep -c "MiniIOMobileFramebuffer: .* selector"
echo -n "tl s: "; strings "$L" | grep -c -F "tl: s "
echo -n "disp0 提及: "; strings "$L" | grep -c "disp0"
echo
echo "===== 4) Metal ====="
strings -n 8 "$L" | grep -F "registration completed" | head -3
echo
echo "===== 5) frame ====="
python3 -c "
d=open('/mnt/c/ios26/s113-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== DONE ====="
</bash>
