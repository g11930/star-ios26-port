#!/bash
L=/mnt/c/ios26/s109-live.bin
echo "===== IOSvcNotify 条数 ====="
strings -n 8 "$L" | grep -c "IOSvcNotify"
echo
echo "===== 所有通知类型 ====="
strings -n 8 "$L" | grep -oE "IOSvcNotify: type=.*" | sort | uniq -c | sort -rn
echo
echo "===== 通知字典（全部）====="
strings -n 8 "$L" | grep -oE "IOSvcDict: notify .*" | sort | uniq -c | sort -rn | head -30
echo
echo "===== 含显示关键字的通知 ====="
strings -n 8 "$L" | grep -E "IOSvcDict: notify .*(disp0|CLCD|Framebuffer|Accelerator)" | head -10
echo
echo "===== 匹配字典总数 ====="
strings -n 8 "$L" | grep -c "IOSvcDict"
echo
echo "===== 帧缓冲 ====="
python3 -c "
d=open('/mnt/c/ios26/s109-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo -n "error22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
