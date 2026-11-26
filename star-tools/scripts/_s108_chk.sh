#!/bash
L=/mnt/c/ios26/s108-live.bin
echo "===== IOSvcDict 条数 ====="
strings -n 8 "$L" | grep -c "IOSvcDict"
echo
echo "===== 全部 dict 内容 ====="
strings -n 8 "$L" | grep -oE "IOSvcDict: .*" | head -50
echo
echo "===== 含 disp0 / CLCD / Framebuffer 的条 ====="
strings -n 8 "$L" | grep -E "IOSvcDict: .*(disp0|CLCD|Framebuffer)" | head -10
echo
echo "===== 帧缓冲非零 ====="
python3 -c "
d=open('/mnt/c/ios26/s108-frame.raw','rb').read()
print('len',len(d),'nonzero',sum(1 for b in d if b))
"
echo "===== 健康 ====="
echo -n "error22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
