#!/bash
cd /root/star26/star-native || exit 1
L=/mnt/c/ios26/s97-live.bin
echo "===== A) IOAcceleratorES 相关内核侧源码 ====="
grep -rn "IOAcceleratorES\|kernel-side lookup\|AnnibaleGPU mechanism" --include=*.cpp --include=*.inc --include=*.c --include=*.h iokit bsd osfmk 2>/dev/null | grep -v "\.bak" | head -20
echo
echo "===== B) 日志里 IOAcceleratorES 全文 ====="
strings "$L" | grep -n "IOAcceleratorES" | head -20
echo
echo "===== C) 日志里 annibalemetal / sbmetal 全文 ====="
strings "$L" | grep -nE "annibalemetal|sbmetal26|AnnibaleGPU" | head -30
echo
echo "===== D) WindowServer / first_frame / swap ====="
strings "$L" | grep -icE "WindowServer"
strings "$L" | grep -iE "first_frame|swap|CARenderServer|render" | head -10
echo
echo "===== DONE ====="
