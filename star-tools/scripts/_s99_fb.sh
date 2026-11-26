#!/bash
L=/mnt/c/ios26/s99-live.bin
echo "===== A) flip / 提交次数 ====="
strings -n 8 "$L" | grep -c "MiniIOMobileFramebuffer: flip"
strings -n 8 "$L" | grep "MiniIOMobileFramebuffer" | head -10
echo
echo "===== B) 用户态显示/surface 相关 ====="
strings -n 8 "$L" | grep -iE "windowserver|surface|displaylink|setDisplay|swapComplete|first_frame|backboardd.*display" | head -25
echo
echo "===== C) 1125/2436 常量来源 ====="
cd /root/star26/star-native && grep -rn "1125\|2436" --include=*.inc --include=*.cpp --include=*.c iokit/ 2>/dev/null | head -8
echo
echo "===== DONE ====="
