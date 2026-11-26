#!/bash
L=/mnt/c/ios26/s107-live.bin
echo "===== 1) 属性是否真的没了 ====="
strings -n 8 "$L" | grep "props after register" | head -2
echo
echo "===== 2) 用户态匹配的类名（按次数）====="
strings -n 8 "$L" | grep -oE "IOSvcMatch(List)?: asks .*" | sed 's/IOSvcMatchList: asks /L /; s/IOSvcMatch: asks /S /' | sort | uniq -c | sort -rn | head -30
echo -n "IOSvcMatch total: "; strings "$L" | grep -c "IOSvcMatch"
echo
echo "===== 3) 显示类查询 ====="
strings -n 8 "$L" | grep -E "IOSvcMatch.*(CLCD|Framebuffer|Backlight|Accelerator|IOSurface)" | head -12
echo
echo "===== 4) open / selector / swap ====="
echo -n "IOSvcOpen total: "; strings "$L" | grep -c "IOSvcOpen"
strings -n 6 "$L" | grep "IOSvcOpen" | grep -E "backboardd|disp0" | head -10
echo -n "selector: "; strings -n 8 "$L" | grep -c "selector"
echo -n "tl s swap: "; strings -n 4 "$L" | grep -c -F "tl: s "
echo
echo "===== 5) 帧缓冲 ====="
python3 -c "
d=open('/mnt/c/ios26/s107-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo -n "error22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
