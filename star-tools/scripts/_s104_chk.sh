#!/bash
L=/mnt/c/ios26/s104-live.bin
echo "===== 1) IOSvcOpen 总数 ====="
echo -n "count: "; strings "$L" | grep -c "IOSvcOpen"
echo
echo "===== 2) 全部 IOSvcOpen（前 60）====="
strings -n 6 "$L" | grep "IOSvcOpen" | head -60
echo
echo "===== 3) backboardd / SpringBoard 的 open ====="
strings -n 6 "$L" | grep "IOSvcOpen" | grep -E "backboardd|SpringBoard" | head -30
echo
echo "===== 4) 是否有人 open disp0 ====="
strings -n 6 "$L" | grep "IOSvcOpen" | grep -i "disp0" | head -10
echo
echo "===== 5) 健康 ====="
echo -n "error=22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
