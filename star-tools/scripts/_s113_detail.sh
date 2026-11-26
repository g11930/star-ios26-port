#!/bash
L=/mnt/c/ios26/s113-live.bin
echo "===== 1) disp0 原文 ====="
strings -n 6 "$L" | grep -B2 -A2 "disp0" | head -30
echo
echo "===== 2) backboardd 生命周期（是否崩）====="
strings -n 8 "$L" | grep -iE "backboardd.*(exit|crash|terminated|spawn|kill|SIG)" | head -15
echo -n "backboardd 重启次数: "; strings "$L" | grep -c "annibale lib loaded pid"
echo
echo "===== 3) selector / 帧相关内核日志 ====="
strings -n 8 "$L" | grep -E "MiniIOMobileFramebuffer|MiniFramebuffer" | head -15
echo
echo "===== 4) 帧缓冲转 PNG ====="
python3 -c "
import subprocess
" 
python3 /mnt/d/桌面/star26-deps/scripts/fb2png.py /mnt/c/ios26/s113-frame.raw /mnt/c/ios26/s113-frame.png 2>&1 | tail -3
echo "===== DONE ====="
</bash>
