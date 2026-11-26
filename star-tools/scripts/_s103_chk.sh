#!/bash
L=/mnt/c/ios26/s103-live.bin
echo "===== 1) regtrace 行（总数/前 30）====="
echo -n "regtrace count: "; strings "$L" | grep -c "regtrace:"
strings -n 6 "$L" | grep "regtrace:" | head -30
echo
echo "===== 2) 提到 disp0 的 regtrace ====="
strings -n 6 "$L" | grep "regtrace:" | grep -i "disp0" | head -20
echo
echo "===== 3) backboardd/SpringBoard 的 regtrace ====="
strings -n 6 "$L" | grep "regtrace:" | grep -E "backboardd|SpringBoard" | head -20
echo
echo "===== 4) 健康检查 ====="
echo -n "error=22: "; strings "$L" | grep -c "error=22"
strings -n 8 "$L" | grep -oE "^2025-[0-9-]+ [0-9:]+" | tail -1
echo "===== DONE ====="
