#!/bash
L=/mnt/c/ios26/s97-live.bin
echo "===== A) SpringBoard 启动阶段关键词 ====="
strings -n 8 "$L" | grep -E "SpringBoard\[33" | grep -Ei "launch|scene|workspace|lock|UIApplication|FrontBoard|BackBoard|display|surface|shell|bootstrap|ready" | tail -30
echo
echo "===== B) backboardd 关键词 ====="
strings -n 8 "$L" | grep -E "backboardd\[39" | grep -Ei "BackBoard|display|surface|WindowServer|render|HID|BTConnection|service" | tail -25
echo
echo "===== C) 全局渲染/显示服务 ====="
strings -n 8 "$L" | grep -iE "BBServer|CARenderServer|IOSurface|IOMobileFramebuffer|WindowServer|render server|GraphicsServices" | head -20
echo
echo "===== D) 崩溃/异常再确认 ====="
strings -n 8 "$L" | grep -E "ReportCrash|CrashReporter|Exception Type|terminating|SIGABRT" | head -12
echo
echo "===== DONE ====="
