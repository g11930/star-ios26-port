#!/bash
L=/mnt/c/ios26/s97-live2.bin
echo "===== s97(t≈480s) backboardd 主线程 284 全部行 ====="
strings -n 6 "$L" | grep -E "backboardd\[39:284\]" | tail -20
echo
echo "===== 是否有 display 启动行（全日志）====="
strings -n 6 "$L" | grep -iE "[Dd]isplay (added|controller|connected)|BKDisplayController|creating display" | head -10
echo
echo "===== 最后时间戳 ====="
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
