#!/bash
L=/mnt/c/ios26/s100-live.bin
echo "===== A) backboardd 显示栈关键词 ====="
strings -n 6 "$L" | grep -E "BKDisplay|DisplayController|display added|displayUUID|CADisplay|DisplayServices|display mode|DisplayMode" | head -25
echo
echo "===== B) backboardd 启动前 20 行（t<10s）====="
strings -n 6 "$L" | grep -E "backboardd\[" | head -20
echo
echo "===== C) 用户态 IOMobileFramebuffer 调用相关 ====="
strings -n 6 "$L" | grep -iE "IOMobileFramebuffer|iomfb|MobileFramebuffer" | head -15
echo "===== DONE ====="
