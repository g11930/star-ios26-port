#!/bash
L=/mnt/c/ios26/s98-live.bin
echo "===== SpringBoard(pid 33) 全部 thread_dump 行 ====="
strings -n 4 "$L" | grep -E "tl: td 33" | head -80
echo
echo "===== launchd(pid 1) 全部 ====="
strings -n 4 "$L" | grep -E "tl: td 1 " | head -60
echo
echo "===== DONE ====="
